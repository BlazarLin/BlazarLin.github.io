---
title: AlgMapReader 流程与内存序说明
categories:
- C++编程
tags:
- c++
- 无锁编程
- 内存序
- 延迟回收
---

# AlgMapReader 流程与内存序说明

## 目的

在检测线程读取工具 map 时避免等待 `mutexAlgMap`，同时保证复检应用、工具删除期间不会访问已经释放的 `BaseTool*`。

本设计由三部分组成：不可变 map 快照、读者活跃版本登记、退役工具延迟回收。

## 核心对象

| 对象 | 作用 |
| --- | --- |
| `__mapName2Algs` | Adapter 写侧当前工具 map，只能在 `mutexAlgMap` 内修改。 |
| `__publishedAlgMap` | 已发布的不可变 `AlgMapSnapshot`，读者无锁读取。 |
| `AlgMapSnapshot::map` | 发布时复制的 `QMap<QString, BaseTool*>`；不拥有工具对象。 |
| `AlgMapSnapshot::version` | 单调递增快照版本。 |
| `AlgMapReader::m_activeVersion` | 当前读者正在使用的快照版本；0 表示未使用工具指针。 |
| `__pendingDeleteTools` | 已从当前 map 移出、等待安全析构的工具。 |

## 检测帧读流程

以 `MainThread::SingleInitProcess()`、`FlowThread::run()` 为例：

1. 线程持有长期复用的 `AlgMapReader` 成员。
2. 每帧创建 `AlgMapFrameGuard`，内部调用 `initialize()` 和 `acquire()`。
3. `acquire()` 取得一个已发布快照，并写入 `m_activeVersion`。
4. 当前帧执行或初始化工具前，按 `AlgToolParam::idName` 从本帧快照重新解析 `BaseTool*`。
   - 在线工具 key 为 `idName`。
   - 复检工具 key 为 `Recheck + idName`。
   - 当前快照找不到该 key 时，说明是已删除的滞后流程项，直接跳过，不能再解引用 `AlgToolParam::AlgoImpl`。
5. Guard 在正常返回、异常展开或提前 `return` 时析构，调用 `endFrame()`，将活跃版本清零。

```text
帧开始 → acquire(V100) → activeVersion=100 → 使用 V100 中的工具
      → Guard 析构 → activeVersion=0
```

## 删除与延迟回收流程

删除工具不再在 `mutexAlgMap` 内直接 `delete`：

```text
mutexAlgMap 内：
  map.take(toolId)
  发布新快照 V101
  pendingDelete 加入 { tool, removedSnapshotVersion=101 }

mutexAlgMap 外：
  尝试回收 pendingDelete
```

回收器扫描所有读者的 `m_activeVersion`：

```text
读者仍在 V100：100 < 101
  → V100 可能仍含已移除工具，不能 delete。

无活跃读者，或所有活跃读者版本 >= 101：
  → 新快照不再含该工具，可以 onToolDeleteAction() + delete。
```

因此，“快照持有期间不释放工具对象”并不是 `shared_ptr<QMap>` 自动管理了 `BaseTool`，而是活跃版本阻止回收器提前析构这些裸指针。

## acquire() 的双重校验

`AlgMapReader::acquire()` 的目标是：只有在读者已经登记为使用某版本，且该版本仍为当前发布版本时，才把 map 返回给调用方。

```text
读取当前版本 V100
→ activeVersion = 100
→ 再读取当前版本
→ 仍是 V100：返回 V100.map
→ 已变成 V101：activeVersion = 0，重新读取最新快照
```

先登记再二次校验，可防止“读者已经取得旧快照、删除者却认为没有旧读者并释放工具”的竞态。

`m_cachedSnapshot` 用于版本不变时复用 QMap 快照，减少每帧 `shared_ptr` 原子读取。`endFrame()` 不清缓存，因为缓存本身不代表仍在使用 `BaseTool*`；能否回收工具只看 `m_activeVersion`。

## 为什么 register/unregister 仍使用 QMutex

`initialize()` 首次使用 reader 时调用 `__registerAlgMapReader()`，析构时调用 `__unregisterAlgMapReader()`。这两次操作需要短暂锁定 `mutexAlgMap`，仅用于修改“读者地址表”。

它们不遍历工具、不执行检测、不落盘。长期线程复用同一个 reader 后，不会每帧重复注册。实际热路径的 `acquire()`、工具查找、算法执行不持有 `mutexAlgMap`。

## memory_order_acquire / memory_order_release

写侧发布快照：

```cpp
std::atomic_store_explicit(&__publishedAlgMap, snapshot,
    std::memory_order_release);
__algMapVersion.store(version, std::memory_order_release);
```

读侧接收发布：

```cpp
std::atomic_load_explicit(&__publishedAlgMap,
    std::memory_order_acquire);
__algMapVersion.load(std::memory_order_acquire);
```

`release` 保证发布动作之前已构造好的快照内容会被推出；读者通过 `acquire` 观察到该发布后，能看到完整初始化的快照内容。它避免编译器或 CPU 将快照构造、快照指针发布、版本号发布在读者可见性上错误重排。

`m_activeVersion.store(version, release)` 与回收器的 `load(acquire)` 同理：回收器能可靠观察读者是否已声明正在使用旧版本。

本设计不需要更强的 `memory_order_seq_cst` 全局顺序；`acquire/release` 已满足发布与回收所需的先后可见性。

## C++17 中 shared_ptr 的原子读写

`__publishedAlgMap` 的类型是：

```cpp
std::shared_ptr<const AlgMapSnapshot>
```

C++17 中不能使用 `std::atomic<std::shared_ptr<T>>`。标准库提供专用自由函数：

```cpp
std::atomic_load_explicit(&sharedPtr, std::memory_order_acquire);
std::atomic_store_explicit(&sharedPtr, newValue, std::memory_order_release);
```

`std::atomic_load_explicit(&__publishedAlgMap, acquire)` 的作用是：原子取得一个独立的 `shared_ptr` 引用，安全增加其引用计数，并以 acquire 语义接收写侧已发布的完整 `AlgMapSnapshot`。

它只保证 `AlgMapSnapshot` 与 QMap 容器本身不被释放；`BaseTool*` 的实际生命周期仍必须由 `m_activeVersion` 和 `__pendingDeleteTools` 协作保护。

## resetNGCount 的用法

`resetNGCount()` 使用函数内局部 `AlgMapReader` 遍历快照，避免在 `mutexAlgMap` 内逐工具 `saveSelf()`。

```text
register（短锁）
→ acquire
→ 清零 NG 计数与 saveSelf（不持有 mutexAlgMap）
→ 函数结束，reader 析构
→ endFrame + unregister（短锁）
```

这只保证工具不会被删除；若允许检测与清零并发执行，`nNGCount` 自身还需使用原子变量或工具内部同步，不能依赖 map 锁解决读写竞争。

## 从长时间 map 锁迁移到快照的关键数据流

### 总体原则

`mutexAlgMap` 仍然存在，但职责收缩为“写侧修改当前 map、发布新快照、维护读者登记表”。下列耗时工作不再在该锁内执行：检测、初始化、关系刷新、逐工具 `saveSelf()`、工具析构。

| 场景 | 原有主要行为 | 当前主要行为 |
| --- | --- | --- |
| 检测/初始化读工具 | `getAlgMapCopy()` 或 map 锁后读取 | `AlgMapFrameGuard` 持有本帧快照。 |
| 新增工具 | 写 map 的同时可能影响读者 | 锁内新增并发布新版本；旧帧继续使用旧快照，新帧看到新工具。 |
| 删除工具 | 锁内 `delete BaseTool` | 锁内退役并发布；锁外、确认旧读者退出后才析构。 |
| `resetNGCount()` | 锁内遍历、清零、逐工具落盘 | 局部 `AlgMapReader` 遍历快照；清零和落盘不持有 map 锁。 |
| `updateToolChooseItem()` | 九个关系函数反复申请 map 锁 | 一次取得快照，独立关系更新锁串行完成九类字段更新。 |

### 新增工具：写侧发布，读侧自然切换

新增工具的关键顺序为：

```text
mutexAlgMap 内：
  创建 BaseTool
  写入 __mapName2Algs[toolId] = tool
  复制并发布新快照 V101
  __algMapVersion = 101
mutexAlgMap 外：
  后续参数、UI、流程操作
```

读侧结果：

```text
已在 V100 中运行的帧：看不到新工具，按旧流程完成。
V101 发布后新开始的帧：取得 V101，能解析并执行新工具。
```

快照发布不复制 `BaseTool` 对象；它复制的是工具 ID 到指针的表。未变化工具在 V100 与 V101 中仍指向同一个对象。

### 删除工具：退役、发布、延迟回收

删除工具不再直接在 `mutexAlgMap` 内调用 `delete`：

```text
mutexAlgMap 内：
  校验检测、初始化、读参状态
  __mapName2Algs.take(toolId)
  发布不含该工具的新快照 V101
  pendingDelete 追加 { tool, removedSnapshotVersion=101 }
mutexAlgMap 外：
  清理 widget 指针、删除参数文件
  尝试回收 pendingDelete
```

回收器只在以下条件成立时析构：

```text
不存在 activeVersion != 0 的 reader
或所有活跃 reader 的最小版本 >= removedSnapshotVersion
```

例如 V100 仍含工具 B，删除 B 后发布 V101：只要有 reader 的 `activeVersion=100`，B 就保持在待回收队列中；V100 帧结束后，回收器才会在锁外执行：

```cpp
tool->onToolDeleteAction();
delete tool;
```

### 检测与初始化：流程缓存必须经过本帧快照校验

`AlgFlowParam::toolParams` 内有历史缓存的 `AlgToolParam::AlgoImpl` 裸指针。工具删除、复检应用或流程任务排队后，该缓存可能落后于当前 map，不能直接解引用。

当前流程为：

```text
AlgMapFrameGuard 构造
  → 当前线程 reader.acquire()
  → 取得本帧 map 快照并登记 activeVersion
  → 按 tool.idName 在本帧快照重新解析 BaseTool*
  → 使用解析出的指针 initialize/process
AlgMapFrameGuard 析构
  → reader.endFrame()
```

ID 解析规则：

```text
在线工具：map key = tool.idName
复检工具：map key = "Recheck" + tool.idName
```

当前快照找不到工具时，说明该流程项已经滞后于 map 发布，直接跳过；不能使用缓存的 `AlgoImpl`。这避免了复检删除工具后在 `AlgoImpl->bUse` 处访问空指针或已回收对象。

### resetNGCount：读者保护对象生命周期，RAII 保护读参状态

`resetNGCount()` 使用函数内局部 `AlgMapReader`。它在整个遍历、计数清零和必要的 `saveSelf()` 期间保持活跃版本：

```text
initialize/register（短暂维护读者表）
→ acquire 快照并登记 activeVersion
→ 遍历快照中符合 nMode 的 BaseTool
→ ParamReadingGuard 构造：setParamReadingStatus(true)
→ nNGCount 清零；确有变化时 saveSelf()
→ ParamReadingGuard 析构：setParamReadingStatus(false)
→ mapReader 析构：endFrame + unregister
```

作用分工如下：

| 机制 | 解决的问题 |
| --- | --- |
| `AlgMapReader::activeVersion` | 整个 reset 期间，被遍历的工具不会因 map 删除而被析构。 |
| `ParamReadingGuard` | 即使 `saveSelf()` 异常或提前退出，也会清除读参状态，避免工具永久不可删除。 |
| `mutexAlgMap` 不在 reset 中持有 | 逐工具落盘不会阻塞 map 发布、检测线程取快照和 UI 查询。 |

`nNGCount` 与检测线程递增仍可能并发读写。该问题属于计数值同步，需由计数原子化或工具内部锁处理，不属于 map 快照生命周期保护范围。

### updateToolChooseItem：快照与关系字段更新分离

`updateToolChooseItem(toolIds)` 的九类关系更新函数不再各自申请 `mutexAlgMap`。调用方流程为：

```text
AlgMapReader.acquire()
→ QMutexLocker(mutexToolRelationUpdate)
→ 使用同一个 AlgMap 快照完成九类关系字段更新
→ endFrame()/析构
```

其中 `mutexToolRelationUpdate` 只用于串行化“补正源、图像源、掩膜源、屏蔽图源、偏差源、角度源、外部工具源、分类源、区域源”的关系写入；它不承担工具对象生命周期保护。生命周期由 reader 与延迟回收负责。

## 使用边界

1. 取得的 `BaseTool*` 只能在对应 reader 的 `acquire()` 与 `endFrame()` 之间使用，不能跨帧缓存。
2. 快照保证单帧工具集合自洽，不保证不同线程在不同时间开始的帧一定使用同一版本。若一批多相机必须固定版本，调度层需要统一取得并传递同一个 `AlgMapSnapshot`。
3. 快照机制只处理 map 结构变化和对象生命周期；工具内部可变参数、NG 计数、算法状态的并发读写仍需各自定义同步策略。
