---
title: c++forward用法
categories: 
- C++编程
tags: 
- c++
- STL分析
---

##  原理：完美转发


> std::forward不是独自运作的，完美转发 = std::forward + 万能引用 + 引用折叠。三者合一才能实现完美转发的效果。


##  基本作用

将一个参数的左右值特性原封不动地转发给其他函数。

##  案例分析

逐步分析以下demo函数输出的结果

```c++
namespace XForward
{
	void func(int& x) {
		qInfo() << "lvalue " << x ;
	}

	void func(int&& x) {
		qInfo() << "rvalue " << x ;
	}

	template<typename T>
	void wrapper(T&& arg) {
		func(arg);	//arg此时已经是个左值了,永远调用左值版本的func
		func(std::forward<T>(arg)); // 具体分析
		func(std::move(arg));//永远调用右值版本的func
	}
}

int x = 42;
XForward::wrapper(x);	// lvalue lvalue rvalue
XForward::wrapper(1);	// lvalue rvalue rvalue
```

func(arg); 固定为左值变量调用，永远是lvalue

func(std::move(arg)); 永远调用右值版本的func

###  XForward::wrapper(x)

实例化wrapper，x输入为左值

```c++
template<typename int &>
void wrapper(int & && arg) {
    func(std::forward<int &>(arg));
}
```

引用折叠 int & &&=>int &

```c++
template<typename int &>
void wrapper(int & arg) {
    func(std::forward<int &>(arg));
}
```

type_traits中std::forward实现

```c++
template <class _Ty>
_NODISCARD constexpr _Ty&& forward(
    remove_reference_t<_Ty>& _Arg) noexcept { // forward an lvalue as either an lvalue or an rvalue
    return static_cast<_Ty&&>(_Arg);
}
```

套入参数 `_Ty = int &`
```c++
template <class int &>
_NODISCARD constexpr int & && forward(
    remove_reference_t<int &>& _Arg) noexcept { // forward an lvalue as either an lvalue or an rvalue
    return static_cast<int & &&>(_Arg);
}
```

引用折叠后
```c++
template <class int &>
_NODISCARD constexpr int & forward(
    remove_reference_t<int &>& _Arg) noexcept { // forward an lvalue as either an lvalue or an rvalue
    return static_cast<int &>(_Arg);//最终的输入参数是左值!!!
}
```

所以最终`std::forward<int &>(arg)`的作用就是将参数强制转型成`int &`，而`int &`为左值。所以，调用左值版本的func。

`func(std::forward<int &>(arg));` =>`func(<int &>(arg));`

###  XForward::wrapper(1);

与左值相似的推理步骤

实例化wrapper，1输入为右值 `int &&`

```c++
template<typename int &&>
void wrapper(int && && arg) {
    func(std::forward<int &&>(arg));
}
```

引用折叠 `int && &&`=>`int &&`

```c++
template<typename int &>
void wrapper(int && arg) {
    func(std::forward<int &&>(arg));
}
```

套入参数 `_Ty = int &&`
```c++
template <class int &&>
_NODISCARD constexpr int && && forward(
    remove_reference_t<int &&>& _Arg) noexcept { // forward an lvalue as either an lvalue or an rvalue
    return static_cast<int && &&>(_Arg);
}
```

引用折叠后
```c++
template <class int &&>
_NODISCARD constexpr int && forward(
    remove_reference_t<int &&>& _Arg) noexcept { // forward an lvalue as either an lvalue or an rvalue
    return static_cast<int &&>(_Arg);//最终的输入参数是左值!!!
}
```

最终`std::forward<int &&>(arg)`的作用就是将参数强制转型成`int &&`，而`int &&`为左值。所以，调用右值版本的func。

`func(std::forward<int &&>(arg));` =>`func(<int &&>(arg));`

一顿操作下来，**保留了参数的左右值属性**，并将其传递给其他函数，实现了forward的基本作用。



参考

[谈谈完美转发(Perfect Forwarding)：完美转发 = 引用折叠 + 万能引用 + std::forward](https://zhuanlan.zhihu.com/p/369203981)

[C++编程之 std::forward](https://blog.csdn.net/Awesomewan/article/details/129582548)


