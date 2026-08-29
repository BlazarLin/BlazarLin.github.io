---
title: 应用复检闪退排查与复现报告
categories:
- C++编程
tags:
- c++
- 多线程
- 堆损坏
- 崩溃排查
---

# 应用复检闪退(0xc0000374)排查与复现报告

## 1. 问题描述

软件在**应用复检(applyRecheck)**期间出现闪退，异常代码为 `0xc0000374`（堆损坏/Heap Corruption），崩溃点位于 `ntdll.dll` 内部。

崩溃发生在 `Adapter::deleteTool()` 批量删除复检工具的过程中，涉及的工具类型主要为 `XZJMMInsSegTool`（AI 实例分割工具）。

---

## 2. 关键代码结构

### 2.1 工具删除流程

```
Adapter::applyRecheck()
  └─ deleteTool(toolName)
       ├─ algImp->onToolDeleteAction()
       └─ delete algImp   ← 触发析构链
            ├─ ~XZJMMInsSegTool()    → _bDelete = true; clearModelHandle();
            ├─ ~BaseAITool()         → 销毁 _imageQueue (ThreadSafeQueue)
            └─ ~BaseTool()           → 销毁其他成员
```

### 2.2 存图线程模式 (BaseAITool)

```cpp
// baseaitool.h 中定义
bool _bDelete = false;
ThreadSafeQueue<ImageSaveInfo> _imageQueue;
std::thread _threadSaveImg;

// XZJMMInsSegTool 构造函数
XZJMMInsSegTool::XZJMMInsSegTool() {
    _threadSaveImg = std::thread(&XZJMMInsSegTool::_saveImage, this);
    _threadSaveImg.detach();  // ← 关键：detach 后主线程无法等待子线程退出
}

// XZJMMInsSegTool 析构函数
~XZJMMInsSegTool() {
    _bDelete = true;  // ← 只设标志，不 notify，不 join
    clearModelHandle();
}

// BaseAITool::_saveImage (子线程执行体)
void BaseAITool::_saveImage() {
    while (!_bDelete) {
        auto data = _imageQueue.wait_end_pop();  // ← 阻塞等待
        // ... 写文件 ...
    }
}
```

### 2.3 ThreadSafeQueue 核心实现

```cpp
template<typename T>
class ThreadSafeQueue {
protected:
    mutable std::mutex mut;
    std::queue<std::shared_ptr<T>> data_queue;
    std::condition_variable data_cond;
public:
    std::shared_ptr<T> wait_end_pop() {
        std::unique_lock<std::mutex> lk(mut);
        data_cond.wait(lk, [this]{ return !data_queue.empty(); });
        auto res = data_queue.front();
        data_queue.pop();
        return res;
    }
    void push(T new_value) {
        // ... size check (无锁) ...
        std::lock_guard<std::mutex> lk(mut);
        data_queue.push(data);
        data_cond.notify_one();
    }
};
```

---

## 3. 根因分析

### 3.1 Bug 本质：detach 线程 + 无安全关闭

析构链的时序：

```
主线程:  ~XZJMMInsSegTool()       ~BaseAITool()
         |                         |
         _bDelete = true           ~ThreadSafeQueue()
         clearModelHandle()          ~std::mutex
                                     ~std::condition_variable
                                     ~std::queue
                                   ~std::thread (已 detach, no-op)
```

存图线程同时在做：

```
存图线程:  while(!_bDelete)
             → _imageQueue.wait_end_pop()
               → std::unique_lock<std::mutex> lk(mut)   // 锁已被析构的 mutex
               → data_cond.wait(...)                     // 等待已被析构的 CV
```

**`_bDelete = true` 和 `~ThreadSafeQueue()` 之间没有同步机制**——设了标志但没有 notify，也没有 join。存图线程可能在以下两种状态：

| 线程状态 | 析构后果 | 表现 |
|---------|---------|------|
| 正在 `wait_end_pop` 持有锁/操作队列 | mutex/queue 被析构时线程正在使用 | 立即崩溃或堆损坏 |
| 阻塞在 `condition_variable::wait` (队列空) | 线程卡在内核态，mutex/CV 内存被释放 | 僵尸线程；堆复用后被唤醒 → 延迟崩溃 |

### 3.2 生产环境崩溃路径

```
1. deleteTool → delete algImp → 析构完成 → 内存归还堆
2. 堆分配器将此内存分配给新对象 (新工具或其他数据结构)
3. 新对象构造/操作 → 覆写原来的 mutex/condition_variable/queue 内存
4. 僵尸线程被唤醒 (新对象 notify 碰巧命中同一 CV 地址，或 spurious wakeup)
5. 线程尝试重新获取已被覆写的 SRWLOCK → 追踪垃圾指针
6. → 0xc0000374 (HEAP CORRUPTION) 或 0xc0000005 (ACCESS VIOLATION) in ntdll.dll
```

崩溃点不在 `deleteTool` 本身，而可能延迟到后续的任意堆操作。这解释了日志中崩溃位置看起来"不相关"的现象。

---

## 4. 复现测试过程

### 4.1 测试 v1：delete 后 push（失败）

**思路**：`new` 工具 → push 数据 → `delete` 工具 → 继续 push

**结果**：Debug 模式下 `delete` 后堆内存被标记为 `0xDD`（MSVC 调试堆），`memset` 或 push 操作直接触发堆保护崩溃，而不是预期的 queue 相关崩溃。本质上是在已释放内存上操作，不是 queue 并发问题。

### 4.2 测试 v2：placement new + memset(0xDD)（失败）

**思路**：`malloc` + placement new → push → 显式析构 → `memset(0xDD)` 覆写 → 等待线程崩溃

**结果**：`0xDD` 对 `bool _bDelete` 而言是非零值（true），线程检查 `!_bDelete` 为 false → 正常退出循环。线程安全退出，不会崩溃。

### 4.3 测试 v3：placement new + memset(0x00)（失败）

**思路**：改用 `0x00` 覆写 → `_bDelete` 变 false → 线程不退出 → 碰到损坏的 mutex → 崩溃

**结果**：不崩溃。原因分析：

- 析构函数设 `_bDelete = true` → `~ThreadSafeQueue` 销毁 mutex/CV/queue
- 线程消费完所有数据后阻塞在 `condition_variable::wait()` → **进入内核态**（Windows 底层 `SleepConditionVariableSRW`）
- `memset(0x00)` 只改用户态内存，**内核不关心用户态内存变化**
- 线程永远卡在内核里不会回到用户态检查 `_bDelete` 或访问 mutex
- 结果：线程成为僵尸（永久阻塞），但不崩溃

**关键发现：`condition_variable::wait` = 内核态睡眠 → 用户态内存覆写无法唤醒线程**

### 4.4 测试 v4：try_pop 替代 wait_end_pop（用户拒绝）

**思路**：用 `try_pop` 替代 `wait_end_pop`，线程始终在用户态（不进内核）→ memset 后必触及损坏内存 → 崩溃

**结果**：理论可行，但用户要求保持 `wait_end_pop` 不变，只改外部调用方式。

### 4.5 测试 v5：原生 CONDITION_VARIABLE + 手动唤醒（用户拒绝）

**思路**：用原生 Windows `SRWLOCK`/`CONDITION_VARIABLE` 替代 `std::mutex`/`std::condition_variable`，同步原语直接嵌在对象内存中。析构后保存 CV 等待链表指针 → memset → 恢复 CV → `WakeAllConditionVariable` 唤醒僵尸线程 → 线程重新获取被覆写的 SRWLOCK → 崩溃。

**结果**：用户要求固定使用 `ThreadSafeQueue`，不更换队列实现。

### 4.6 测试 v6：持续 push + memset（最终方案）

**思路**：保持 `ThreadSafeQueue` + `wait_end_pop` 不变。增加一个 producer 线程持续 push → 队列**始终非空** → `wait_end_pop` 中 predicate `!data_queue.empty()` 始终为 true → **线程永远不进入 `condition_variable::wait`（不进内核态）** → 线程在 lock → pop → unlock 的用户态紧密循环中全速运行 → `memset` 覆写 mutex → 下次 lock/unlock 碰到 0xCD → ntdll 崩溃。

```cpp
// 核心逻辑
std::thread producer([tool, &keepPushing]() {
    while (keepPushing) tool->_queue.push("item_" + ...);
});
std::this_thread::sleep_for(20ms);
memset(queueAddr, 0xCD, corruptSize);  // mutex 变成 0xCDCDCDCD
// worker/producer 下次操作 mutex → ntdll!RtlAcquireSRWLockExclusive 崩溃
```

**崩溃机制**：

- 正持锁的线程释放时：`ReleaseSRWLockExclusive` 读到 `0xCDCDCDCD` → "有等待者"标志位 → 追踪垃圾等待链表指针 → ACCESS VIOLATION
- 等锁的线程获取时：`AcquireSRWLockExclusive` 读到 `0xCDCDCDCD` → "已锁定" → 追踪垃圾等待链表 → ACCESS VIOLATION
- 侥幸过了 mutex：`deque._Map = 0xCDCDCDCD` → `front()` 解引用垃圾指针 → ACCESS VIOLATION

---

## 5. 根因总结

| 要素 | 说明 |
|------|------|
| **直接原因** | detach 线程在对象析构后继续访问已释放的 mutex/queue 内存 |
| **为什么用 detach** | `_saveImage` 是后台存图线程，设计时选择了 fire-and-forget 模式 |
| **为什么析构不安全** | 只设 `_bDelete = true`，不 notify 条件变量，不 join 线程 |
| **为什么是延迟崩溃** | 线程常阻塞在内核态 wait；堆复用后才暴露问题 |
| **为什么难复现** | 崩溃依赖堆复用时序 + 线程唤醒时机，属于经典 Heisenbug |

---

## 6. 修复建议

### 方案 A：析构时安全关闭线程（推荐）

```cpp
~XZJMMInsSegTool() {
    _bDelete = true;
    _imageQueue.data_cond.notify_all();  // ← 新增：唤醒阻塞线程
    if (_threadSaveImg.joinable())
        _threadSaveImg.join();           // ← 新增：等待线程退出
    clearModelHandle();
}
```

前提：不 detach，改为 join。

### 方案 B：用 `std::jthread` + `stop_token`（C++20）

```cpp
std::jthread _threadSaveImg;
// 构造
_threadSaveImg = std::jthread([this](std::stop_token st) {
    while (!st.stop_requested()) {
        auto data = _imageQueue.wait_end_pop_or_stop(st);
        if (!data) break;
        // ... 写文件 ...
    }
});
// 析构自动 request_stop + join
```

### 方案 C：最小改动（保持 detach，增加 notify）

如果无法改为 join，至少在析构时 notify 并等待一段时间：

```cpp
~XZJMMInsSegTool() {
    _bDelete = true;
    _imageQueue.clear();                 // 已有：notify_all + 清空
    std::this_thread::sleep_for(100ms);  // 给线程时间退出
    clearModelHandle();
}
```

> **注意**：方案 C 仍然不安全——sleep 不能保证线程一定退出。**方案 A 是唯一正确的修复。**

---

## 7. 排查过程中的其他发现

### 7.1 ThreadSafeQueue::push 的无锁 size 检查

```cpp
void push(T new_value) {
    if (data_queue.size() > m_LimitNum) {  // ← 无锁读取！data race
        try_pop();
    }
    std::lock_guard<std::mutex> lk(mut);
    // ...
}
```

`data_queue.size()` 在锁外调用，与其他线程的 `pop` 存在数据竞争。虽然此处只是近似限流不影响正确性，但严格来说是 UB。

### 7.2 `wait_end_pop` 与内核态等待

`std::condition_variable::wait()` 在 MSVC 上最终调用 `SleepConditionVariableSRW`（内核态等待）。析构 `std::condition_variable` 在 Windows 上是空操作（`CONDITION_VARIABLE` 是 trivial 类型），**不会唤醒等待中的线程**。这意味着：

- 析构后线程成为僵尸（卡在内核）
- 线程持有的栈内存有效，但 `this` 指向的对象已销毁
- 堆复用时可能意外唤醒僵尸线程

### 7.3 XToolTest 中 static 全局变量的陷阱

排查过程中发现 `TestToolBase.h` 中 `mapTools`/`mapLibs` 使用 `static` 声明：

```cpp
// 错误：每个 .cpp 包含此头文件都有独立副本
static QMap<QString, BaseTool*> mapTools;
```

已修正为 `extern` + 单一定义：

```cpp
// TestToolBase.h
extern QMap<QString, std::shared_ptr<BaseTool>> mapTools;
// TestToolBase.cpp
QMap<QString, std::shared_ptr<BaseTool>> mapTools;
```
