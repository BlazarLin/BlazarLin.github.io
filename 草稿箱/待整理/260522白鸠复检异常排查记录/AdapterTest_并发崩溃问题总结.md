---
title: Adapter 复检并发崩溃问题总结
categories:
- C++编程
tags:
- c++
- 多线程
- 堆损坏
- 崩溃排查
---

# Adapter 复检并发崩溃问题总结

## 1. 问题现象

### 1.1 现场描述

- **场景**：软件在检测过程中，主线程执行复检（`recheckCam` / `applyRecheck`），4 个相机检测子线程持续调用工具的 `initialize` / `process`。
- **表现**：程序闪退，异常未被业务层捕获。
- **异常类型**：`0xC0000374` — **堆损坏（STATUS_HEAP_CORRUPTION）**。
- **复现难度**：压力测试约 **8 小时** 才出现一次。

### 1.2 日志最后记录

```
[Info] 相机1工具进入复检
[Info] 相机1复检工具清理
[Info] 复检读取目录: .../OfflineCamera1
```

说明崩溃发生在 `recheckCam(1)` 流程中后段：清理复检工具 → 拷贝参数 → `__restoreSpec` → 加载 JSON 参数（`loadSelf` → `setJsonObj`）附近。

### 1.3 DMP 堆栈（两次不同现场）

**现场 A — 主线程 / 复检路径**

```
BaseParam::setJsonObj(...)          basetool.cpp ~874
BaseParam::load(...)                basetool.cpp
Adapter::__restore(...)             adapter.cpp ~1759
Adapter::__restoreSpec(...)         adapter.cpp ~1797
Adapter::recheckCam(...)            adapter.cpp ~2612
```

**现场 B — 检测子线程 / process 路径**

```
XToolTest main lambda               main_adapter.cpp ~303
BaseTool::process(...)              basetool.cpp ~5731
QVector<ContourOut>::append(...)    basetool.cpp
QVector::realloc / operator=
→ ntdll RtlFreeHeap → 0xC0000374 堆损坏
```

**关键观察（现场 B）**

- `camTools` 中工具指针地址「看起来正常」（如 `0x000001888dcd2d50`）。
- 进入 `process()` 后，`this` 成员全部 **无法读取内存** → **`this` 已是野指针**。
- 崩溃点（`QVector::realloc`）≠ 案发点；堆元数据在此前已被破坏。

---

## 2. 架构与并发模型

### 2.1 线程分工（测试程序 `main_adapter.cpp`）

| 角色 | 行为 |
|------|------|
| 4 个相机子线程 | 循环：`getAlgMap()` → 筛选本相机工具 → `initialize` / `process` |
| 主线程 | 循环：`onEnterRecheck` → `recheckCam` → `onLeaveRecheck`（1~4 相机 + `applyRecheck`） |
| 输入线程 | 等待回车，设置 `bStopAll` 退出 |

### 2.2 Adapter 中的关键数据结构

```cpp
QMap<QString, BaseTool*> __mapName2Algs;   // 工具名 → 工具指针
QMutex mutexAlgMap{ QMutex::Recursive };   // 递归互斥锁
```

```cpp
QMap<QString, BaseTool*>* Adapter::getAlgMap()
{
    QMutexLocker lockerMap(&mutexAlgMap);
    return &__mapName2Algs;   // 锁在 return 后立即释放
}
```

### 2.3 复检与真实检测工具的关系

- 复检工具 key 带 `Recheck_` 前缀，由 `__generateTool(..., recheck=true)` **新建独立实例**。
- 真实检测工具（如 `XZJBlobTool_1_0_1`）与复检工具（如 `Recheck_XZJBlobTool_1_0_1`）是 **不同对象**。
- `recheckCam` 当前逻辑 **不会删除** 真实检测工具（`deleteTool` 已注释）。
- 因此：**不是**「复检 `loadSelf` 与检测 `process` 写同一个 `BaseTool` 对象」导致的直接竞争。

---

## 3. 根因分析

### 3.1 主因：QMap 无锁并发读写（迭代器 / 结构竞争）

**危险用法（修复前）**

```cpp
auto* algMap = _adapter->getAlgMap();  // 仅瞬间持锁
for (auto it = algMap->begin(); it != algMap->end(); ++it) {
    // 无锁遍历，与 recheckCam 修改 __mapName2Algs 并发
    camTools.insert(it.key(), it.value());
}
```

**写端（主线程 `recheckCam`）**

- 全程持有 `mutexAlgMap`。
- `__generateTool` 向 `__mapName2Algs` **插入** 新复检工具：`__mapName2Algs[toolName] = _algImpl`。
- QMap 底层为 **红黑树**，插入/删除会触发 **节点旋转、重平衡**。

**读端（检测线程）**

- 拿到 map **指针** 后锁已释放。
- 无锁 `begin()` / `end()` / `it++` 遍历同一棵红黑树。

**后果**

- 遍历过程中树结构被修改 → 迭代器失效 / 读到错误的 `BaseTool*`。
- 指针值可能仍「像」合法堆地址，但对象已无效 → `process()` 内 `this` 无法读内存。
- 后续 `QVector::append` / `realloc` 触发堆检查 → `0xC0000374`。

> **注意**：「加锁后拷贝 map」只有在 **拷贝动作本身也在锁内** 才安全；`getAlgMap()` 返回指针后再 `localCopy = *algMap` 仍可能在与写线程并发拷贝时出问题。

### 3.2 次因：BaseAITool 存图线程 detach + 无法可靠退出

**代码（`xzjmminssegtool.cpp` 构造函数）**

```cpp
_threadSaveImg = std::thread(&XZJMMInsSegTool::_saveImage, this);
_threadSaveImg.detach();
```

**析构（`~XZJMMInsSegTool`）**

```cpp
_bDelete = true;
clearModelHandle();
// 未 join 存图线程
```

**`_saveImage` 循环（`baseaitool.cpp`）**

```cpp
while (!_bDelete) {
    auto data = _imageQueue.wait_end_pop();  // 仅等待队列非空，不检查 _bDelete
    // ...
}
```

**问题**

1. 队列为空时线程阻塞在 `wait()`，`_bDelete = true` **无法唤醒** 线程。
2. `detach` 后析构不等待线程结束 → 对象释放后线程仍可能访问 `this` → **use-after-free**。
3. 可能 **间接踩坏堆**，与主因叠加，使崩溃更难定位。

### 3.3 为何 8 小时才复现一次？

| 因素 | 说明 |
|------|------|
| 时间窗口极窄 | 无锁遍历 map 可能仅 **微秒级**；`recheckCam` 修改 map 也只在持锁段内 **微秒~毫秒** |
| 调度随机性 | 两线程「读遍历」与「写插入」精确重叠概率极低 |
| 堆损坏延迟爆发 | 越界写可能不立刻崩溃，直到后续 `malloc/free/realloc` 才触发 `0xC0000374` |
| 指针「看起来合法」 | 错误 value 可能仍落在堆地址范围，多数轮次不会立刻 SEH |

粗算：单次碰撞概率约 **10⁻⁸ 量级**，4 线程 + 长时间运行后，数小时出现一次符合预期。

---

## 4. 拓展知识点

### 4.1 堆损坏 vs 访问违规

| 异常码 | 含义 | 特点 |
|--------|------|------|
| `0xC0000005` | 访问违规 | 通常立即在非法地址访问处崩溃 |
| `0xC0000374` | 堆损坏 | 崩溃点常在 `RtlFreeHeap` / `realloc`，**真凶在更早的写坏堆** |

调试原则：**崩溃栈顶 ≠ 案发位置**，需 Page Heap / Application Verifier 找首次踩内存处。

### 4.2 Qt QMap 线程安全

- **QMap 本身非线程安全**。
- 多线程：一读一写或两写，未同步 → 未定义行为（UB）。
- 「只读原有 N 个 key、只写 Recheck key」**不能**保证安全：红黑树是整体结构，插入新节点仍可能旋转，影响遍历路径。

### 4.3 `getAlgMap()` 返回指针的陷阱

```cpp
QMap* p = getAlgMap();  // 锁已释放
// 此后任何对 *p 的遍历/插入/删除都与 Adapter 内部操作竞争
```

正确模式：**在锁保护下完成拷贝或筛选**，再释放锁使用副本。

### 4.4 `std::thread::detach` 与对象生命周期

- `detach` = 线程与 `std::thread` 对象分离，**无法再 join**。
- 若线程仍持有 `this` 指针，对象析构必须保证：线程已退出，或线程不再访问成员。
- 条件变量等待应同时检查 **退出标志**（如 `_bDelete`），析构时 **notify + join**。

### 4.5 SEH 与 C++ 异常

- MSVC 下 `__try/__except` 不能与含 C++ 析构对象的函数混用 → **C2712**。
- 做法：将 SEH 封装到无 `QString`/STL 析构的纯 C 风格函数中。

### 4.6 日志与 DMP

- 异步日志线程写文件 + 20MB 轮转，避免检测/复检线程阻塞在 IO。
- 生产环境保留 **Full Dump** 或 **Mini Dump + 堆栈**，配合 WinDbg `!analyze -v`。

---

## 5. 解决方案

### 5.1 已实施：Adapter 增加 `getAlgMapCopy()`

**声明（`adapter.h`）**

```cpp
QMap<QString, BaseTool*> getAlgMapCopy();
```

**实现（`adapter.cpp`）**

```cpp
QMap<QString, BaseTool*> Adapter::getAlgMapCopy()
{
    QMutexLocker lockerMap(&mutexAlgMap);
    return __mapName2Algs;   // 在锁内完成整表拷贝
}
```

**检测线程用法（`main_adapter.cpp`）**

```cpp
auto algMapCopy = _adapter->getAlgMapCopy();
for (auto it = algMapCopy.begin(); it != algMapCopy.end(); ++it) {
    // 筛选本相机、非 Recheck 工具
}
// 后续 process 使用的是拷贝中的 BaseTool*，与 map 结构变更解耦
```

**效果**

- 消除「无锁遍历红黑树」导致的迭代器失效 / 错误指针。
- 拷贝完成后，map 增删 Recheck 节点不影响本次遍历。
- **注意**：若未来会 **delete 真实工具对象**，还需保证 `process` 期间对象不被释放（引用计数或持锁策略）。

### 5.2 建议：Qt_Vision / 正式检测流程同步改造

凡是通过 `getAlgMap()` 拿指针再遍历的地方，应改为：

- `getAlgMapCopy()`，或
- 显式 `QMutexLocker` + 在锁内完成筛选/拷贝。

### 5.3 建议：修复 BaseAITool 存图线程

**目标**：析构时线程必退出，禁止 detach 后 use-after-free。

**思路示例**

```cpp
// 析构
~BaseAITool() {
    _bDelete = true;
    _imageQueue.notify_all();  // 需扩展 ThreadSafeQueue：wait 条件含 _bDelete 或 poison pill
    if (_threadSaveImg.joinable())
        _threadSaveImg.join();
}

// wait_end_pop 改为可中断，或循环 try_pop + sleep
while (!_bDelete) {
    if (_imageQueue.try_pop(imageInfo)) { ... }
    else std::this_thread::sleep_for(10ms);
}
```

构造函数：**不要 detach**，保留 `joinable` 线程供析构 join。

### 5.4 验证手段

| 手段 | 用途 |
|------|------|
| `test_qmap_race.cpp` | 三种模式对比：`--unsafe` / `--copy` / `--safe` |
| `main_adapter.cpp` 压测 | 4 相机检测 + 主线程复检循环 |
| Page Heap (`gflags /p /enable`) | 首次踩内存即崩溃 |
| Application Verifier | 检测 UAF、double-free、锁问题 |
| WinDbg `~*k` | 确认崩溃线程是主线程还是检测线程 |

---

## 6. 排查清单（Checklist）

- [ ] 所有 `getAlgMap()` 调用点：是否在无锁下遍历？→ 改为 `getAlgMapCopy()` 或锁内拷贝。
- [ ] `recheckCam` / `applySpec` 是否会删除或替换检测中的工具指针？
- [ ] AI 工具（`BaseAITool` 子类）析构是否 join 存图线程？
- [ ] `ThreadSafeQueue::wait_end_pop` 是否支持退出唤醒？
- [ ] 崩溃是否为 `0xC0000374`？→ 优先怀疑堆损坏，用 Page Heap 复现。
- [ ] DMP 中崩溃线程：主线程 → 复检/加载参数；子线程 → 检测/process + 可能 map 竞争。

---

## 7. 相关文件索引

| 文件 | 说明 |
|------|------|
| `XToolTest/main_adapter.cpp` | 4 相机压测 + 复检循环 + 异步日志 |
| `XToolTest/test_qmap_race.cpp` | QMap 并发竞争 Demo（三种模式） |
| `Adapter/adapter.cpp` | `getAlgMap` / `getAlgMapCopy` / `recheckCam` / `__restoreSpec` |
| `BaseTool/basetool.cpp` | `setJsonObj` / `process`（`runtimeMutex`） |
| `BaseTool/baseaitool.cpp` | `_saveImage` 存图线程 |
| `XZJMMInsSegTool/xzjmminssegtool.cpp` | 构造函数 detach 存图线程 |

---

## 8. 结论

1. **直接触发检测线程崩溃的主因**：检测线程在 **无锁** 下遍历 `__mapName2Algs`，与复检线程 **持锁插入** Recheck 工具并发，导致 QMap 迭代异常 / 读到无效 `BaseTool*`。
2. **修复核心**：`getAlgMapCopy()` — 在 `mutexAlgMap` 保护下拷贝整表，检测侧只遍历副本。
3. **独立隐患**：`BaseAITool::_saveImage` detach + 析构不 join → use-after-free，可能加剧堆损坏，应单独修复。
4. **低复现率** 是并发 UB 的典型特征，不能因「难复现」而忽视；压测 + Page Heap + 专用 Demo 是有效验证手段。

---

*文档生成自 Adapter 复检压测与崩溃分析会话，适用于 XZJ-VISION / XToolTest 场景。*
