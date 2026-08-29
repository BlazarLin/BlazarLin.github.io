---
title: c++新特性
categories: 
- C++编程
tags: 
- c++11
- c++14
---

此文非原创内容搬运自，：[学习笔记：C++ 11新特性.md](https://github.com/0voice/cpp_new_features/blob/main/%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0%EF%BC%9AC%2B%2B%2011%E6%96%B0%E7%89%B9%E6%80%A7.md)

# c++新特性

C++11引入了auto和decltype关键字，使用它们可以在编译期就推导出变量或者表达式的类型，方便开发者编码的同时也简化了代码。

## auto

auto可以让编译器在编译器就推导出变量的类型，看代码：

```c++
auto a = 10; // 10是int型，可以自动推导出a是int
int i = 10;auto b = i; // b是int型
auto d = 2.0; // d是double型
```

这就是auto的基本用法，可以通过=右边的类型推导出变量的类型。

### auto推导规则

直接看代码

代码1：

```c++
int i = 10;
auto a = i, &b = i, *c = &i; // a是int，b是i的引用，c是i的指针，auto就相当于int
auto d = 0, f = 1.0; // error，0和1.0类型不同，对于编译器有二义性，没法推导
auto e; // error，使用auto必须马上初始化，否则无法推导类型
```

代码2：

```c++
void func(auto value) {} // error，auto不能用作函数参数

class A {
    auto a = 1; // error，在类中auto不能用作非静态成员变量
    static auto b = 1; // error，这里与auto无关，正常static int b = 1也不可以
    static const auto int c = 1; // ok
};

void func2() {
    int a[10] = {0};
    auto b = a; // ok
    auto c[10] = a; // error，auto不能定义数组，可以定义指针
    vector<int> d;
    vector<auto> f = d; // error，auto无法推导出模板参数
}
```

auto的限制：

- auto的使用必须马上初始化，否则无法推导出类型
- auto在一行定义多个变量时，各个变量的推导不能产生二义性，否则编译失败

- auto不能用作函数参数
- 在类中auto不能用作非静态成员变量

- auto不能定义数组，可以定义指针
- auto无法推导出模板参数

再看这段代码：

```c++
int i = 0;
auto *a = &i; // a是int*
auto &b = i; // b是int&
auto c = b; // c是int，忽略了引用

const auto d = i; // d是const int
auto e = d; // e是int

const auto& f = e; // f是const int&
auto &g = f; // g是const int&
```

首先，介绍下，这里的cv是指const 和volatile

推导规则

- 在不声明为引用或指针时，auto会忽略等号右边的引用类型和cv限定
- 在声明为引用或者指针时，auto会保留等号右边的引用和cv属性

### 什么时候使用auto？

这里没有绝对答案，在不影响代码代码可读性的前提下尽可能使用auto是蛮好的，复杂类型就使用auto，int、double这种就没有必要使用auto了，看下面这段代码：

```c++
auto func = [&] {
    cout << "xxx";
}; // 对于func难道不使用auto吗，反正是不关心lambda表达式究竟是什么类型。

auto asyncfunc = std::async(std::launch::async, func);
// 对于asyncfunc难道不使用auto吗，懒得写std::futurexxx等代码，而且也记不住它返回的究竟是什么...
```

## decltype

上面介绍auto用于推导变量类型，而decltype则用于推导表达式类型，这里只用于编译器分析表达式的类型，表达式实际不会进行运算，上代码：

```c++
int func() { return 0; }
decltype(func()) i; // i为int类型

int x = 0;
decltype(x) y; // y是int类型
decltype(x + y) z; // z是int类型
```

注意：decltype不会像auto一样忽略引用和cv属性，decltype会保留表达式的引用和cv属性

```c++
cont int &i = 1;
int a = 2;
decltype(i) b = 2; // b是const int&
```

### decltype推导规则

对于decltype(exp)有

- exp是表达式，decltype(exp)和exp类型相同
- exp是函数调用，decltype(exp)和函数返回值类型相同

- 其它情况，若exp是左值，decltype(exp)是exp类型的左值引用

```c++
int a = 0, b = 0;
decltype(a + b) c = 0; // c是int，因为(a+b)返回一个右值
decltype(a += b) d = c;// d是int&，因为(a+=b)返回一个左值

d = 20;
cout << "c " << c << endl; // 输出c 20
```

## auto和decltype的配合使用

auto和decltype一般配合使用在推导函数返回值的类型问题上。

下面这段代码

```c++
template<typename T, typename U>
return_value add(T t, U u) { // t和v类型不确定，无法推导出return_value类型
    return t + u;
}
```

上面代码由于t和u类型不确定，那如何推导出返回值类型呢，可能会想到这种

```c++
template<typename T, typename U>
decltype(t + u) add(T t, U u) { // t和u尚未定义
    return t + u;
}
```

这段代码在C++11上是编译不过的，因为在decltype(t +u)推导时，t和u尚未定义，就会编译出错，所以有了下面的叫做返回类型后置的配合使用方法：

```c++
template<typename T, typename U>
auto add(T t, U u) -> decltype(t + u) {
    return t + u;
}
```

返回值后置类型语法就是为了解决函数返回值类型依赖于参数但却难以确定返回值类型的问题。

### 完美转发

完美转发指可以写一个接受任意实参的函数模板，并转发到其它函数，目标函数会收到与转发函数完全相同的实参，转发函数实参是左值那目标函数实参也是左值，转发函数实参是右值那目标函数实参也是右值。那如何实现完美转发呢，答案是使用std::forward()。

```c++
void PrintV(int &t) {
    cout << "lvalue" << endl;
}

void PrintV(int &&t) {
    cout << "rvalue" << endl;
}

template<typename T>
void Test(T &&t) {
    PrintV(t);
    PrintV(std::forward<T>(t));

    PrintV(std::move(t));
}

int main() {
    Test(1); // lvalue rvalue rvalue
    int a = 1;
    Test(a); // lvalue lvalue rvalue
    Test(std::forward<int>(a)); // lvalue rvalue rvalue
    Test(std::forward<int&>(a)); // lvalue lvalue rvalue
    Test(std::forward<int&&>(a)); // lvalue rvalue rvalue
    return 0;
}
```

分析

- Test(1)：1是右值，模板中T &&t这种为万能引用，右值1传到Test函数中变成了右值引用，但是调用PrintV()时候，t变成了左值，因为它变成了一个拥有名字的变量，所以打印lvalue，而PrintV(std::forward<T>(t))时候，会进行完美转发，按照原来的类型转发，所以打印rvalue，PrintV(std::move(t))毫无疑问会打印rvalue。
- Test(a)：a是左值，模板中T &&这种为万能引用，左值a传到Test函数中变成了左值引用，所以有代码中打印。

- Test(std::forward<T>(a))：转发为左值还是右值，依赖于T，T是左值那就转发为左值，T是右值那就转发为右值。



## C++11新特性之列表初始化

C++11新增了列表初始化的概念。

在C++11中可以直接在变量名后面加上初始化列表来进行对象的初始化。

```c++
struct A {
    public:
    A(int) {}
    private:
    A(const A&) {}
};
int main() {
    A a(123);
    A b = 123; // error
    A c = { 123 };
    A d{123}; // c++11

    int e = {123};
    int f{123}; // c++11

    return 0;
}
```

列表初始化也可以用在函数的返回值上

```c++
std::vector<int> func() {
    return {};
}
```

### 列表初始化的一些规则

首先说下聚合类型可以进行直接列表初始化，这里需要了解什么是聚合类型：

1. 类型是一个普通数组，如int[5]，char[]，double[]等
2. 类型是一个类，且满足以下条件：

- - 没有用户声明的构造函数
  - 没有用户提供的构造函数(允许显示预置或弃置的构造函数)

- - 没有私有或保护的非静态数据成员
  - 没有基类

- - 没有虚函数
  - 没有{}和=直接初始化的非静态数据成员

- - 没有默认成员初始化器

```c++
struct A {
    int a;
    int b;
    int c;
    A(int, int){}
};
int main() {
    A a{1, 2, 3};// error，A有自定义的构造函数，不能列表初始化
}
```

上述代码类A不是聚合类型，无法进行列表初始化，必须以自定义的构造函数来构造对象。

```c++
struct A {
    int a;
    int b;
    virtual void func() {} // 含有虚函数，不是聚合类
};

struct Base {};
struct B : public Base { // 有基类，不是聚合类
    int a;
    int b;
};

struct C {
    int a;
    int b = 10; // 有等号初始化，不是聚合类
};

struct D {
    int a;
    int b;
    private:
    int c; // 含有私有的非静态数据成员，不是聚合类
};

struct E {
    int a;
    int b;
    E() : a(0), b(0) {} // 含有默认成员初始化器，不是聚合类
};
```

上面列举了一些不是聚合类的例子，对于一个聚合类型，使用列表初始化相当于对其中的每个元素分别赋值；对于非聚合类型，需要先自定义一个对应的构造函数，此时列表初始化将调用相应的构造函数。

### std::initializer_list

平时开发使用STL过程中可能发现它的初始化列表可以是任意长度，大家有没有想过它是怎么实现的呢，答案是std::initializer_list，看下面这段示例代码：

```c++
struct CustomVec {
    std::vector<int> data;
    CustomVec(std::initializer_list<int> list) {
        for (auto iter = list.begin(); iter != list.end(); ++iter) {
            data.push_back(*iter);
        }
    }
};
```

这个std::initializer_list其实也可以作为函数参数。

注意：std::initializer_list<T>，它可以接收任意长度的初始化列表，但是里面必须是相同类型T，或者都可以转换为T。

### 列表初始化的好处

列表初始化的好处如下：

1. 方便，且基本上可以替代括号初始化
2. 可以使用初始化列表接受任意长度

1. 可以防止类型窄化，避免精度丢失的隐式类型转换

什么是类型窄化，列表初始化通过禁止下列转换，对隐式转化加以限制：

- 从浮点类型到整数类型的转换
- 从 long double 到 double 或 float 的转换，以及从 double 到 float 的转换，除非源是常量表达式且不发生溢出

- 从整数类型到浮点类型的转换，除非源是其值能完全存储于目标类型的常量表达式
- 从整数或无作用域枚举类型到不能表示原类型所有值的整数类型的转换，除非源是其值能完全存储于目标类型的常量表达式

示例：

```c++
int main() {
    int a = 1.2; // ok
    int b = {1.2}; // error

    float c = 1e70; // ok
    float d = {1e70}; // error

    float e = (unsigned long long)-1; // ok
    float f = {(unsigned long long)-1}; // error
    float g = (unsigned long long)1; // ok
    float h = {(unsigned long long)1}; // ok

    const int i = 1000;
    const int j = 2;
    char k = i; // ok
    char l = {i}; // error

    char m = j; // ok
    char m = {j}; // ok，因为是const类型，这里如果去掉const属性，也会报错
}
```

打印如下：

```c++
test.cc:24:17: error: narrowing conversion of ‘1.2e+0’ from ‘double’ to ‘int’ inside { } [-Wnarrowing]
    int b = {1.2};
                ^
test.cc:27:20: error: narrowing conversion of ‘1.0000000000000001e+70’ from ‘double’ to ‘float’ inside { } [-Wnarrowing]
     float d = {1e70};

test.cc:30:38: error: narrowing conversion of ‘18446744073709551615’ from ‘long long unsigned int’ to ‘float’ inside { } [-Wnarrowing]
    float f = {(unsigned long long)-1};
                                     ^
test.cc:36:14: warning: overflow in implicit constant conversion [-Woverflow]
    char k = i;
             ^
test.cc:37:16: error: narrowing conversion of ‘1000’ from ‘int’ to ‘char’ inside { } [-Wnarrowing]
    char l = {i};
```

## C++11新特性std::function和lambda表达式

c++11新增了`std::function`、`std::bind`、`lambda`表达式等封装使函数调用更加方便。

## `std::function`

讲`std::function`前首先需要了解下什么是可调用对象

满足以下条件之一就可称为可调用对象：

- 是一个函数指针
- 是一个具有`operator()`成员函数的类对象(传说中的仿函数)，lambda表达式

- 是一个可被转换为函数指针的类对象
- 是一个类成员(函数)指针

- bind表达式或其它函数对象

而`std::function`就是上面这种可调用对象的封装器，可以把`std::function`看做一个函数对象，用于表示函数这个抽象概念。`std::function`的实例可以存储、复制和调用任何可调用对象，存储的可调用对象称为`std::function`的目标，若`std::function`不含目标，则称它为空，调用空的`std::function`的目标会抛出`std::bad_function_call`异常。

使用参考如下实例代码：

```c++
std::function<void(int)> f; // 这里表示function的对象f的参数是int，返回值是void
#include <functional>
#include <iostream>

struct Foo {
    Foo(int num) : num_(num) {}
    void print_add(int i) const { std::cout << num_ + i << '\n'; }
    int num_;
};

void print_num(int i) { std::cout << i << '\n'; }

struct PrintNum {
    void operator()(int i) const { std::cout << i << '\n'; }
};

int main() {
    // 存储自由函数
    std::function<void(int)> f_display = print_num;
    f_display(-9);

    // 存储 lambda
    std::function<void()> f_display_42 = []() { print_num(42); };
    f_display_42();

    // 存储到 std::bind 调用的结果
    std::function<void()> f_display_31337 = std::bind(print_num, 31337);
    f_display_31337();

    // 存储到成员函数的调用
    std::function<void(const Foo&, int)> f_add_display = &Foo::print_add;
    const Foo foo(314159);
    f_add_display(foo, 1);
    f_add_display(314159, 1);

    // 存储到数据成员访问器的调用
    std::function<int(Foo const&)> f_num = &Foo::num_;
    std::cout << "num_: " << f_num(foo) << '\n';

    // 存储到成员函数及对象的调用
    using std::placeholders::_1;
    std::function<void(int)> f_add_display2 = std::bind(&Foo::print_add, foo, _1);
    f_add_display2(2);

    // 存储到成员函数和对象指针的调用
    std::function<void(int)> f_add_display3 = std::bind(&Foo::print_add, &foo, _1);
    f_add_display3(3);

    // 存储到函数对象的调用
    std::function<void(int)> f_display_obj = PrintNum();
    f_display_obj(18);
}
```

从上面可以看到`std::function`的使用方法，当给`std::function`填入合适的参数表和返回值后，它就变成了可以容纳所有这一类调用方式的函数封装器。`std::function`还可以用作回调函数，或者在C++里如果需要使用回调那就一定要使用`std::function`，特别方便。

## `std::bind`

使用`std::bind`可以将可调用对象和参数一起绑定，绑定后的结果使用`std::function`进行保存，并延迟调用到任何需要的时候。

`std::bind`通常有两大作用：

- 将可调用对象与参数一起绑定为另一个`std::function`供调用
- 将n元可调用对象转成m(m < n)元可调用对象，绑定一部分参数，这里需要使用`std::placeholders`

具体示例：

```c++
#include <functional>
#include <iostream>
#include <memory>

void f(int n1, int n2, int n3, const int& n4, int n5) {
    std::cout << n1 << ' ' << n2 << ' ' << n3 << ' ' << n4 << ' ' << n5 << std::endl;
}

int g(int n1) { return n1; }

struct Foo {
    void print_sum(int n1, int n2) { std::cout << n1 + n2 << std::endl; }
    int data = 10;
};

int main() {
    using namespace std::placeholders;  // 针对 _1, _2, _3...

    // 演示参数重排序和按引用传递
    int n = 7;
    // （ _1 与 _2 来自 std::placeholders ，并表示将来会传递给 f1 的参数）
    auto f1 = std::bind(f, _2, 42, _1, std::cref(n), n);
    n = 10;
    f1(1, 2, 1001);  // 1 为 _1 所绑定， 2 为 _2 所绑定，不使用 1001
    // 进行到 f(2, 42, 1, n, 7) 的调用

    // 嵌套 bind 子表达式共享占位符
    auto f2 = std::bind(f, _3, std::bind(g, _3), _3, 4, 5);
    f2(10, 11, 12);  // 进行到 f(12, g(12), 12, 4, 5); 的调用

    // 绑定指向成员函数指针
    Foo foo;
    auto f3 = std::bind(&Foo::print_sum, &foo, 95, _1);
    f3(5);

    // 绑定指向数据成员指针
    auto f4 = std::bind(&Foo::data, _1);
    std::cout << f4(foo) << std::endl;

    // 智能指针亦能用于调用被引用对象的成员
    std::cout << f4(std::make_shared<Foo>(foo)) << std::endl;
}
```

## `lambda`表达式

lambda表达式可以说是c++11引用的最重要的特性之一，它定义了一个匿名函数，可以捕获一定范围的变量在函数内部使用，一般有如下语法形式：

```c++
auto func = [capture] (params) opt -> ret { func_body; };
```

其中`func`是可以当作`lambda`表达式的名字，作为一个函数使用，`capture`是捕获列表，`params`是参数表，`opt`是函数选项(mutable之类)， ret是返回值类型，func_body是函数体。

一个完整的lambda表达式：

```c++
auto func1 = [](int a) -> int { return a + 1; };
auto func2 = [](int a) { return a + 2; };
cout << func1(1) << " " << func2(2) << endl;
```

如上代码，很多时候lambda表达式返回值是很明显的，c++11允许省略表达式的返回值定义。

`lambda`表达式允许捕获一定范围内的变量：

- `[]`不捕获任何变量
- `[&]`引用捕获，捕获外部作用域所有变量，在函数体内当作引用使用

- `[=]`值捕获，捕获外部作用域所有变量，在函数内内有个副本使用
- `[=, &a]`值捕获外部作用域所有变量，按引用捕获a变量

- `[a]`只值捕获a变量，不捕获其它变量
- `[this]`捕获当前类中的this指针

lambda表达式示例代码：

```c++
int a = 0;
auto f1 = [=](){ return a; }; // 值捕获a
cout << f1() << endl;

auto f2 = [=]() { return a++; }; // 修改按值捕获的外部变量，error
auto f3 = [=]() mutable { return a++; };
```

代码中的f2是编译不过的，因为修改了按值捕获的外部变量，其实lambda表达式就相当于是一个仿函数，仿函数是一个有`operator()`成员函数的类对象，这个`operator()`默认是`const`的，所以不能修改成员变量，而加了`mutable`，就是去掉`const`属性。

还可以使用lambda表达式自定义stl的规则，例如自定义sort排序规则：

```c++
struct A {
    int a;
    int b;
};

int main() {
    vector<A> vec;
    std::sort(vec.begin(), vec.end(), [](const A &left, const A &right) { return left.a < right.a; });
}
```

### 总结

`std::function`和`std::bind`在平时编程过程中封装函数更加的方便，而lambda表达式将这种方便发挥到了极致，可以在需要的时间就地定义匿名函数，不再需要定义类或者函数等，在自定义STL规则时候也非常方便，让代码更简洁，更灵活，提高开发效率。

## C++11新特性之模板改进

C++11关于模板有一些细节的改进：

- 模板的右尖括号
- 模板的别名

- 函数模板的默认模板参数

### 模板的右尖括号

C++11之前是不允许两个右尖括号出现的，会被认为是右移操作符，所以需要中间加个空格进行分割，避免发生编译错误。

### 模板的别名

C++11引入了using，可以轻松的定义别名，而不是使用繁琐的typedef。

```c++
int main() {
    std::vector<std::vector<int>> a; // error
    std::vector<std::vector<int> > b; // ok
}
```

使用using明显简洁并且易读，大家可能之前也见过使用typedef定义函数指针之类的操作。

```c++
typedef void (*func)(int, int); 
using func = void (*)(int, int); // 起码比typedef容易看的懂
```

上面的代码使用using起码比typedef容易看的懂一些，但是我还是看不懂，因为我从来不用这种来表示函数指针，用std::function()、std::bind()、std::placeholder()、lambda表达式它不香吗。

### 函数模板的默认模板参数

C++11之前只有类模板支持默认模板参数，函数模板是不支持默认模板参数的，C++11后都支持。

```c++
template <typename T, typename U=int>
class A {
    T value;  
};

template <typename T=int, typename U> // error
class A {
    T value;  
};
```

类模板的默认模板参数必须从右往左定义，而函数模板则没有这 个限制。

```c++
template <typename R, typename U=int>
R func1(U val) {
   return val;
}

template <typename R=int, typename U>
R func2(U val) {
    return val;
}

int main() {
    cout << func1<int, double>(99.9) << endl; // 99
    cout << func1<double, double>(99.9) << endl; // 99.9
    cout << func1<double>(99.9) << endl; // 99.9
    cout << func1<int>(99.9) << endl; // 99
    cout << func2<int, double>(99.9) << endl; // 99
    cout << func1<double, double>(99.9) << endl; // 99.9
    cout << func2<double>(99.9) << endl; // 99.9
    cout << func2<int>(99.9) << endl; // 99
    return 0;
}
```


## 参考

auto与decltype、完美转发 摘抄自：[学习笔记：C++ 11新特性.md](https://github.com/0voice/cpp_new_features/blob/main/%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0%EF%BC%9AC%2B%2B%2011%E6%96%B0%E7%89%B9%E6%80%A7.md)

