---
title: std::condition_variable 使用简介
categories:
- C++编程
tags:
- c++
- 多线程
- condition_variable
---

# std::condition_variable 使用简介

> 适用范围：C++17 / C++20，工业视觉 / 实时图像处理场景下的线程间事件同步原语。

---

## TL;DR（一句话）

`std::condition_variable` 是 **线程间"事件通知"原语**，必须和 `std::mutex` 配合使用；核心是 `wait(lock, predicate)` + `notify_one / notify_all`；工程铁律是 **wait 一律带 predicate**，**notify 时机先 lock 改状态、解锁、再 notify**。

---

## What：它是什么、为什么需要它

- 让一个或多个线程在条件不满足时阻塞休眠，被通知后再醒过来检查条件。
- **必须与 `std::mutex` 搭配**：mutex 保护"条件 + 数据"，cv 负责"先放手把锁让出来去睡，被叫醒再回来抢锁"。

三件替代品都做不到的事：

1. 消费者若用 `while (!cond) { sleep(1ms); }` —— 浪费 CPU，延迟还不可控。
2. `sem_t` 没有"条件"语义。
3. `QWaitCondition`（Qt）等价机制，Qt 跨线程还可直接 `QMetaObject::invokeMethod(..., Qt::QueuedConnection)`。

---

## 核心 API

| 类别     | API                                        | 说明                                                                                  |
| -------- | ------------------------------------------ | ------------------------------------------------------------------------------------- |
| 等待     | `wait(unique_lock, predicate)`             | 释放锁并阻塞，直到 predicate 为 true 才返回。**最常用版本**                            |
| 等待     | `wait(unique_lock)`                        | 裸 wait，**不推荐用**（spurious wakeup、lost wakeup 都等着）                          |
| 等待     | `wait_for(unique_lock, dur, predicate)`    | 带超时，返回 `bool`：true 表示因 predicate 满足返回，false 表示超时且 predicate 仍 false |
| 等待     | `wait_until(unique_lock, tp, predicate)`   | 等到绝对时间点                                                                        |
| 通知     | `notify_one()`                             | 唤醒**一个**等待者                                                                    |
| 通知     | `notify_all()`                             | 唤醒**全部**等待者                                                                    |

---

## How：正确范式（可直接复用）

### 模板 1：单条件生产者 - 消费者

```cpp
#include <mutex>
#include <condition_variable>
#include <queue>
#include <chrono>

class FrameQueue {
public:
    void push(Frame f) {
        {
            std::lock_guard<std::mutex> lk(m_);
            q_.push(std::move(f));
        }
        cv_.notify_one();                 // unlock 之后再 notify，避免 lost wakeup
    }

    Frame pop(std::chrono::milliseconds timeout) {
        std::unique_lock<std::mutex> lk(m_);
        if (!cv_.wait_for(lk, timeout, [&]{ return !q_.empty(); })) {
            return {};                    // 超时返回空帧
        }
        Frame f = std::move(q_.front());
        q_.pop();
        return f;
    }

private:
    std::mutex m_;
    std::condition_variable cv_;
    std::queue<Frame> q_;
};
```

### 模板 2：一个 cv 管多类事件（**工业视觉最常需要**）

```cpp
struct Work {
    std::queue<Frame> q;
    bool stopping = false;
    bool config_changed = false;
    std::mutex m;
    std::condition_variable cv;
};

enum class WaitKind { GotData, Stopped, ConfigChanged };

WaitKind wait_for_event(Work& w, std::chrono::milliseconds d) {
    std::unique_lock<std::mutex> lk(w.m);
    bool ok = w.cv.wait_for(lk, d, [&]{
        return !w.q.empty() || w.stopping || w.config_changed;
    });
    if (!ok)             return WaitKind::Stopped;   // 超时
    if (w.stopping)      return WaitKind::Stopped;
    if (!w.q.empty())    return WaitKind::GotData;
    return WaitKind::ConfigChanged;
}

void set_stopping(Work& w) {
    {
        std::lock_guard<std::mutex> lk(w.m);
        w.stopping = true;
    }
    w.cv.notify_all();   // 这里必须 notify_all：可能有人在等数据
}
```

### 模板 3：双 cv 分工（队列 cv + 队列清空 cv）

```cpp
class JobQueue {
    std::mutex m_;
    std::condition_variable data_cv_;     // 队列非空时唤醒
    std::condition_variable done_cv_;     // 队列空且没人跑时唤醒
    std::queue<Job> q_;
    bool stop_ = false;
    int active_workers_ = 0;

public:
    Job take() {
        std::unique_lock<std::mutex> lk(m_);
        data_cv_.wait(lk, [&]{ return stop_ || !q_.empty(); });
        if (stop_) return {};
        Job j = std::move(q_.front());
        q_.pop();
        ++active_workers_;
        return j;
    }

    void finish_one() {
        std::lock_guard<std::mutex> lk(m_);
        --active_workers_;
        if (q_.empty() && active_workers_ == 0)
            done_cv_.notify_all();        // 让"等队列清空"的人醒来
    }
};
```

---

## Why：底层三步原子与两类经典坑

### 1. `wait` 内部三步原子操作（**必须**原子）

伪代码：

```
atomically:
    release mutex
    block on this cv
whenever woken (notify / spurious / timeout):
atomically:
    re-acquire mutex
```

`wait(lock, pred)` 把这个状态机封死：

- 进入前你已持有 `unique_lock`；
- 不满足 `pred`，原子地"释放锁 + 阻塞"；
- 被唤醒后原子地"重抢锁 + 再判断 `pred`"，不满足继续睡，**直到 `pred` 返回 true 才从 wait 返回**。

带 predicate 的 wait 等价于（标准明文规定）：

```cpp
while (!pred()) {
    wait_until_pred_true();
}
```

> **必须用 `std::unique_lock`，不能用 `lock_guard`**：wait 操作需要释放锁的能力，lock_guard 没有。

### 2. Spurious wakeup（虚假唤醒）

POSIX 标准允许 `pthread_cond_wait` 没有 signal/broadcast 自行返回，Windows 实现也允许。**历史原因，性能实现需要**。

```cpp
// 错：
std::unique_lock<std::mutex> lk(m);
cv.wait(lk);
process();              // 假醒 → 状态还不符合 → 错的处理

// 对：
cv.wait(lk, [&]{ return ready; });   // predicate 形式天然 while-loop
```

### 3. Lost wakeup（唤醒丢失）

经典死锁成因：

```
consumer                                producer
--------                                --------
  锁 m                                  -
  if (!ready)                           -
    cv.wait(m)  ← 还没走到这            -
            ──────────────→          锁 m
                                        ready = true
                                        cv.notify_one()   ← 没人等着，通知空气
  现在睡着了，永远不会被叫醒
```

规避方式两件套：

- consumer 端 **先抢锁、再 check、再 wait**；
- producer 端 **先抢锁、改状态、释放锁、再 notify**。
- notify 放在 unlock 之外更稳（避免 producer 拿锁阻塞，consumer 抢锁排队）。

代码上：模板 1 "先 lock_guard 再 notify_one" 的写法就是规避范例。

### 4. `notify_one` vs `notify_all` 怎么选

| 场景                                                    | 选什么         | 理由                                                |
| ------------------------------------------------------- | -------------- | --------------------------------------------------- |
| 任务队列 → 多个 worker 任一可消费                       | `notify_one`   | 一次只给一份活就行                                  |
| 多类事件共存（数据 / 停止 / 配置）                      | `notify_all`   | 等待者关心的事件可能不同，让所有人自己重检 predicate |
| 状态 0 → 1，只想让一个后续观察                          | `notify_one`   | 减少抢锁 thundering herd                            |
| 状态转变使多个等待者都需重检（如 shutdown）              | `notify_all`   | 比如 shutdown，N 个 worker 都要尽快知道             |
| 不确定时                                                | `notify_all`   | 偏 bug 防御；丢失通知的损失通常比 thundering herd 大 |

> 工程口诀：**"状态变化有谁能被遗漏吗？" 有 → `notify_all`，没有 → `notify_one`。**

### 5. notify 是"等待侧抢到锁后"，不是"立刻执行"

调用 `notify_one/all` 时等待线程还睡着。唤醒后等待线程要从 wait 中**重新抢 mutex**。所以：

- 调用 `notify` 的线程 **一般不应仍持有 mutex**；
- 否则等待线程要在信号队列里多排一会儿队（不算 bug，但延迟增大，性能浪费）。

### 6. `wait_for` 返回值陷阱

```cpp
bool ok = cv_.wait_for(lk, 50ms, [&]{ return ready; });
```

- 返回 **true** ：**因为 pred 满足而返回**（不是因超时）。
- 返回 **false**：**超时 + pred 仍 false**。
- 边界：pred 自己变成 true 的同时 50ms 也到了，**返回是 true 不是 false**。

> 想"超时就干活，不管条件满足没"：

```cpp
if (cv_.wait_for(lk, 50ms, [&]{ return ready; })) {
    // 条件满足，干活
} else {
    // 超时；ready 可能仍 false，也可能是 true 之后又变 false
}
```

> 注意：等待期间 pred 变 true 又变 false，wait_for 仍返回 true（"看到过 true"）。这类状态要做成单调累积型才安全。

---

## 常见坑（按踩频率排序）

1. **裸 `cv.wait(lk)` 无 predicate** —— spurious wakeup 直接打脸。
2. **修改状态后忘 notify** —— 死锁。
3. **notify 写在持有锁的代码块末尾** —— 等待线程抢锁排队，唤醒延迟；不算 bug 但不推荐。
4. **predicate 捕获栈引用** —— 等待期间栈对象先析构，结果未定义。predicate 只捕获值 / by-value / shared_ptr。
5. **`cv` 拿来等 `std::atomic`** —— 行得通但 predicate 要改成读 atomic；持 mutex 等 atomic 会牺牲性能。
6. **多 cv 滥用** —— 一类事件一个 cv 是平衡点；再多就拆类；真要那么多事件分流，考虑 Qt 的 `QMetaObject::invokeMethod(..., QueuedConnection)` 把通知做成消息。

---

## 工业视觉里最常用的几个模式

1. **算法管线帧 ready 信号**：检测线程 ↔ 算法线程。每帧处理结束 `notify_one` 通知下游拉下一帧。
2. **多相机同步触发**：每个相机完成取流 `notify`，主线程 `wait` 全部到齐再处理——配 latch / barrier 更直接（C++20 有 `std::barrier` / `std::latch`）。
3. **长跑 worker 的 graceful shutdown**：stop flag + `notify_all`，所有 worker 醒来自检退出。比 `pthread_cancel` 安全一万倍。
4. **节流 / 限速**：每拍 `wait_for` 固定时长，让出 CPU，避免空转。
5. **批处理队列 + size watermark**：cv 等到"累积 N 帧"或"超时"两者择一响，见模板 2 的 `wait_for`。

---

## C++20 / 23 替代与补充

如果可以用 C++20：

- **"等 N 件事都发生"**：`std::latch` / `std::barrier`，比 cv + counter 干净得多。
- **shutdown**：`std::jthread` 的 stop_token + cv 写起来最少代码：

```cpp
std::jthread worker([&](std::stop_token st){
    std::unique_lock<std::mutex> lk(m);
    cv.wait(lk, [&]{ return st.stop_requested() || !q.empty(); });
    // ...
});
// 析构 jthread 自动 request_stop + join + 唤醒 cv
```

---

## 一句话总结

**`std::condition_variable` 是"释放锁+阻塞+被叫醒后重抢锁"的三步原子同步原语，必须配合 mutex，必须带 predicate；`notify_one/all` 是"让等待者重新抢锁重检条件"的意思，不是"立刻起线程"。** 工业视觉里遇到"线程 A 等线程 B 处理完某帧"或"shutdown 信号"，先想 cv + stop_flag；遇到"等 N 个相机都准备就绪"再想 latch / barrier。

---

## 关联阅读

- `260713-stdthread生命周期管控.md` —— 配套的 `std::thread` 生命周期 / join / detach 行为
