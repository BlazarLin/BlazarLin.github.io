---
title: c++并行使用手册
categories: 
- C++编程
tags: 
- c++
- 并行处理
---
## opencv并行

使用cv::parallel_for_函数对目标函数进行并行加速

官方函数原型

```c++
inline void parallel_for_(const Range& range, std::function<void(const Range&)> functor, double nstripes=-1.)
{
    parallel_for_(range, ParallelLoopBodyLambdaWrapper(functor), nstripes);
}
#endif
```

使用案例：求取0-1000的和与最大值

```c++
std::atomic<int> _nSumValue = 0;
std::atomic<int> _nMax = 0;
cv::parallel_for_(cv::Range(0, 1000), [&](const cv::Range& range) {

    for (int i = range.start; i < range.end; i++)
    {
    // 求和
    _nSumValue += i;

    // 求最大值
    if (i > _nMax)
    {
    _nMax = i;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }

});
```

上述代码中，存在2个原子变量`_nSumValue`和`_nMax`，是为了避免出现多线程竞争资源时，变量同时累加导致结果不一致。
若为原始int型变量，观察多次运行结果，发现每次运行的值不一致！如下

![image-cvparallel_wrong_result](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/cvparallel_wrong_result.png)

为了避免此种现象的发生

- 变量改为原子型
- 增加互斥锁



## openMP

### vs项目配置

![image-openmp_vs_config](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/openmp_vs_config.png)

验证openMP是否开启成功：

```c++
#pragma omp parallel for
		for (int i = 0; i < 4; i++)
			cout << omp_get_thread_num() << endl;

// << 输出四个存在不相等的数值则表示则开启成功
// << 输出0000开启失败!
```






### openMP指令

- 考虑一个简单的例子，两个线程都试图同时更新变量x：

| **THREAD 1:**                                                | **THREAD 2:**                                                |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| update(x) { x = x + 1 }<br />x=0<br />update(x)<br />print(x) | update(x) { x = x + 1 }<br />x=0<br />update(x)<br />print(x) |

- 一种可能的执行顺序：
  - 线程1初始化 `x` 为0并调用
  - 线程1将 `x` 加1，`x` 现在等于1
  - 线程2初始化 `x` 为0并调用 `update(x)`，x现在等于0
  - 线程1输出 `x`，它等于0而不是1
  - 线程2将 `x` 加1，`x` 现在等于1
  - 线程2打印 `x` 为1

- 为了避免这种情况，必须在两个线程之间同步 `x` 的更新，以确保产生正确的结果。
- OpenMP 提供了各种同步结构，这些构造控制每个线程相对于其他团队线程的执行方式。

####  `master` 指令

- `master` 指令指定了一个区域，该区域只由团队的主线程执行。团队中的所有其他线程都将跳过这部分代码。
- 这个指令没有隐含的障碍( `implied barrier` )。

```c++
#pragma omp master  newline
    structured_block
```

- 进入或跳出一个 `master` 代码块是非法的。

####  `critical` 指令

- `critical` 指令指定了一个只能由一个线程执行的代码区域。

```c++
#pragma omp critical [ name ]  newline
    structured_block
```

注意事项

- 如果一个线程当前在一个 `critical` 区域内执行，而另一个线程到达该 `critical` 区域并试图执行它，那么它将阻塞，直到第一个线程退出该 `critical` 区域。
- 可选的名称使多个不同的临界区域存在：
  - 名称充当全局标识符。具有相同名称的不同临界区被视为相同的区域。
  - 所有未命名的临界段均视为同一段。

限制条件

- 进入或跳出一个 `critical` 代码块是非法的。

- `Fortran only: The names of critical constructs are global entities of the program. If a name conflicts with any other entity, the behavior of the program is unspecified.`

结构示例

- 团队中的所有线程都将尝试并行执行，但是由于 `x` 的增加由 `critical` 结构包围，在任何时候只有一个线程能够读/增量/写 `x`。

```c++
#include <omp.h>

int main() { 
    int x; 
    x = 0;

#pragma omp parallel shared(x) 
            { 
                #pragma omp critical x = x + 1; } /* end of parallel region */ 
            return 0; 
    
           }
```

####  `reduction` 指令

用归约变量为每个线程创建一个私有的变量，用来存储自己归约的结果，并将最终结果写入全局共享变量，所以归约的代码不需要critical保护也不会发生冲突


### 使用案例分析

求取0-1000的和与最大值

```c++
#pragma omp parallel for reduction(+:_nSumValue)
    for (int i = 0; i < 1000; i++)
    {
        _nSumValue += i;
        // 求最大值
        if (i > _nMax)
        {
            _nMax = i;
        }
    }
```

`reduction`归约操作对指定变量`_nSumValue`求和操作，并将最终结果赋值给主线程中的sum变量。

在上面的程序当中我们使用了一个子句 `reduction(+:_nSumValue)` 在每个线程里面对变量 _nSumValue进行拷贝，然后在线程当中使用这个拷贝的变量，这样的话就不存在数据竞争了，因为每个线程使用的 _nSumValue是不一样的，在 reduction 当中还有一个加号➕，这个加号表示如何进行规约操作，所谓规约操作简单说来就是多个数据逐步进行操作最终得到一个不能够在进行规约的数据。

例如在上面的程序当中我们的规约操作是 + ，因此需要将线程 1 和线程 2 的数据进行 + 操作，即线程 1 的 _nSumValue加上 线程 2 的 _nSumValue值，然后将得到的结果赋值给全局变量 _nSumValue，这样的话我们最终得到的结果就是正确的。

如果有 4 个线程的话，那么就有 4 个线程本地的 _nSumValue（每个线程一个 _nSumValue）。那么规约（reduction）操作的结果等于：

`(((_nSumValue1 + _nSumValue2) + _nSumValue3) +_nSumValue4) `其中 _nSumValuei 表示第 i 个线程的得到的 _nSumValue。



### 参考引用

1、[OpenMP 教程（一） 深入剖析 OpenMP reduction 子句](https://juejin.cn/post/7163929178335608863)

2、[OpenMP中文教程](http://www.uml.org.cn/c%2B%2B/202301054.asp)

3、[OpemMP中文教程](https://juejin.cn/post/6871036114577129479#heading-67)