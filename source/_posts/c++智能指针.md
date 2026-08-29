---
title: c++智能指针
categories: 
- C++编程
tags: 
- c++
- STL分析
---

# c++智能指针

std::shared_ptr

std::weak_ptr

std::unique_ptr

## 一、shared_ptr

最常用的只能指针类，具有自动delete对象，引用计数等功能。

头文件
```c++
#include <memory>
```
构造方法
```c++
// 较优
auto smart_ptr = std::make_shared<int>();

// 不推荐
auto p1 = new int;
std::shared_ptr<int> smart_ptr2(p1);
```

返回裸指针

```c++
auto smart_ptr = std::make_shared<int>();
auto originPtr = smart_ptr.get();
```

### shared_ptr<T>模板类常用成员方法

| 成员方法名      | 功 能                                                        |
| --------------- | ------------------------------------------------------------ |
| operator=()     | 重载赋值号，使得同一类型的 shared_ptr 智能指针可以相互赋值。 |
| operator*()     | 重载 * 号，获取当前 shared_ptr 智能指针对象指向的数据。      |
| operator->()    | 重载 -> 号，当智能指针指向的数据类型为自定义的结构体时，通过 -> 运算符可以获取其内部的指定成员。 |
| swap()          | 交换 2 个相同类型 shared_ptr 智能指针的内容。                |
| reset()         | 当函数没有实参时，该函数会使当前 shared_ptr 所指堆内存的引用计数减 1，同时将当前对象重置为一个空指针；当为函数传递一个新申请的堆内存时，则调用该函数的 shared_ptr 对象会获得该存储空间的所有权，并且引用计数的初始值为 1。 |
| get()           | 获得 shared_ptr 对象内部包含的普通指针。                     |
| use_count()     | 返回同当前 shared_ptr 对象（包括它）指向相同的所有 shared_ptr 对象的数量。 |
| unique()        | 判断当前 shared_ptr 对象指向的堆内存，是否不再有其它 shared_ptr 对象再指向它。 |
| operator bool() | 判断当前 shared_ptr 对象是否为空智能指针，如果是空指针，返回 false；反之，返回 true。 |

### 特点

1. 引用计数
    每一个shared_ptr的拷贝都指向相同的内存，每次拷贝都会触发引用计数+1，每次生命周期结束析构的时候引用计数-1，在最后一个shared_ptr析构的时候，内存才会释放。

  ```c++
class MyClass
{
public:
	MyClass() { std::cout << "构造函数" << std::endl; };
	~MyClass() { std::cout << "析构函数" << std::endl;  };

private:

};
int main()
{
    std::shared_ptr<MyClass> sp = std::make_shared<MyClass>(); // 创建智能指针
    std::cout << sp.use_count() << std::endl; // 打印引用计数
    {
        std::shared_ptr<MyClass> sp2(sp); // 创建另一个智能指针
        std::cout << sp.use_count() << std::endl; // 打印引用计数
    } // sp2生命周期结束，sp引用计数减1
    std::cout << sp.use_count() << std::endl; // 打印引用计数
}
/*
输出信息:
构造函数
1
2
1
析构函数
*/

  ```

 

2. 自定义删除器

   智能指针还可以自定义删除器，在引用计数为0的时候自动调用删除器来释放对象的内存。

   对于申请的**动态数组**来说，shared_ptr 指针默认的释放规则是**不支持释放数组**的，只能自定义对应的释放规则，才能正确地释放申请的堆内存。

   但是对于数组来说，未定义下标运算符，访问数组元素很麻烦，建议改用`unique_ptr`。

   ```c++
   //指定 default_delete 作为释放规则
   std::shared_ptr<int> ptrL1(new int[10], std::default_delete<int[]>());
   
   // 智能指针自定义释放规则
   std::shared_ptr<int> ptrL2(new int[10], [](int* p) { 
       delete []p; 
       std::cout << "自定义删除" << std::endl; 
   });
   // 定义下标运算符，访问数组元素很麻烦
   *(ptrL2.get() + 5) = 10;
   ```

   


###  规避点
1. 不要用一个裸指针初始化多个shared_ptr，会出现**double_free**导致程序崩溃

   ```c++
   int* ptr = new int;
   std::shared_ptr<int> p1(ptr);
   std::shared_ptr<int> p2(ptr);//错误
   ```

2. 通过shared_from_this()返回this指针，不要把this指针作为shared_ptr返回出来，因为this指针本质就是裸指针，通过this返回可能 会导致重复析构，不能把this指针交给智能指针管理。

   ```c++
   class MyCar :public std::enable_shared_from_this<MyCar>
   {
   public:
   	std::shared_ptr<MyCar> get_ptr() {
   		return shared_from_this();
   	}
   	~MyCar() {
   		std::cout << "free ~Mycar()" << std::endl;
   	}
   private:
   
   };
   
   MyCar* _myCar = new MyCar();
   std::shared_ptr<MyCar> _myCar1(_myCar);
   std::shared_ptr<MyCar> _myCar2 = _myCar->get_ptr();
   // std::shared_ptr<MyCar> _myCar2(_myCar); // error
   std::cout << _myCar1.use_count() << std::endl;
   std::cout << _myCar2.use_count() << std::endl;
   
   /*
   >>> 2
   >>> 2
   既保证引用计数正确性，也避免double free重复析构
   */
   
   ```

3. 尽量使用make_shared，少用new，防止使用原始指针创建多个引用计数体系(规避第一点)。

   ```c++
   // 不推荐
   int* ptr = new int;
   std::shared_ptr<int> p1(ptr);
   
   // 推荐
   auto ptrShare = std::make_shared<int>();
   ```

4. 不要delete get()返回来的裸指针。

5. 不是new出来的空间要自定义删除器。

6. 要避免循环引用，循环引用导致内存永远不会被释放，造成内存泄漏。



## 二、std::weak_ptr

weak_ptr可以从一个shared_ptr或者另一个weak_ptr对象构造，获得资源的观测权（辅助share_ptr）。但weak_ptr**没有共享资源**，它的构造不会引起指针引用计数的增加。

### 特点

1. 使用weak_ptr的成员函数use_count()可以观测资源的引用计数，本身的构造与析构不会影响引用计数；

2. 成员函数expired()的功能等价于use_count()==0（更快），表示被观测的资源(也就是shared_ptr的管理的资源)已经不复存在；

3. lock()方法判定对象是否为空；

   ```c++
   std::function<void(std::weak_ptr<int> weak)> obs = [&](std::weak_ptr<int> weak) {
   	std::cout << "expired:" << weak.expired() << "\n";
       if (auto observe = weak.lock()) {
           std::cout << "\tobserve() able to lock weak_ptr<>, value=" << *observe << "\n";
       }
       else {
           std::cout << "\tobserve() unable to lock weak_ptr<>\n";
       }
   };
   
   std::weak_ptr<int> ptrWeek;
   obs(ptrWeek);
   
   {
       auto shared = std::make_shared<int>(68);
       ptrWeek = shared;
       obs(ptrWeek);
   }
   
   obs(ptrWeek);
   
   /*输出结果
   expired:1
   	observe() unable to lock weak_ptr<>
   expired:0
   	observe() able to lock weak_ptr<>, value=68
   expired:1
   	observe() unable to lock weak_ptr<>
   */
   ```

   

4. 解决shared_ptr的循环引用；

   ```c++
   class ObjectA{
   public:
       shared_ptr<ObjectB> b_ptr;
   public:
       ObjectA(){cout<<"Constructor of A"<<endl;}
       ~ObjectA(){cout<<"Destructor of A"<<endl;}
   };
   
   class ObjectB{
   public:
       shared_ptr<ObjectA> a_ptr;
   public:
       ObjectB(){cout<<"Constructor of B"<<endl;}
       ~ObjectB(){cout<<"Destructor of B"<<endl;}
   };
   
   if(1)
   {
       shared_ptr<ObjectA> pObjA(new ObjectA());
       shared_ptr<ObjectB> pObjB(new ObjectB());
       pObjA->b_ptr = pObjB;
       pObjB->a_ptr = pObjA;
   }
   /*输出信息，没有调用析构函数
   Constructor of A
   Constructor of B
   */
   
   ```

   将ObjectA和ObjectB的成员都换成weak_ptr类型，weak_ptr不会导致引用计数的改变。

   ```c++
   class ObjectA{
   public:
       weak_ptr<ObjectB> b_ptr;
   public:
       ObjectA(){cout<<"Constructor of A"<<endl;}
       ~ObjectA(){cout<<"Destructor of A"<<endl;}
   };
   
   class ObjectB{
   public:
       weak_ptr<ObjectA> a_ptr;
   public:
       ObjectB(){cout<<"Constructor of B"<<endl;}
       ~ObjectB(){cout<<"Destructor of B"<<endl;}
   };
   
   if(1)
   {
       shared_ptr<ObjectA> pObjA(new ObjectA());
       shared_ptr<ObjectB> pObjB(new ObjectB());
       pObjA->b_ptr = pObjB;
       pObjB->a_ptr = pObjA;
   }
   /*输出信息，没有调用析构函数
   Constructor of A
   Constructor of B
   Destructor of B
   Destructor of A
   */
   ```


## 三、std::unique_ptr

### 使用场景

1. 通过指针占有(不共享它的指针)并管理另一对象，并在 unique_ptr 离开作用域时释放该对象。
2. 仅能移动，无法复制到其他 unique_ptr（move_only）的类型，转移一个 std::unique_ptr 将会把所有权也从源指针转移给目标指针（源指针被置空）。

### 特点

1. 管理单个对象

   传统方法

   ```c++
   int *p = new int(86);
   // ...（可能会抛出异常,而没有执行delete）
   delete p;
   ```

   unique_ptr 指针创建成功，其析构函数都会被调用，确保动态资源被释放

   ```c++
   unique_ptr<int> p(new int(86));
   ```

   

2. 管理动态分配的对象数组

   ```c++
   unique_ptr<int[]> p(new int[5] {1, 2, 3, 4, 5});
   p[0] = 0;   // 重载了operator[]
   ```

3. 与shared_ptr区别

   shared_ptr允许有多个指针指向同一个对象，unique_ptr独占所指向的对象。





## 参考

[std::weak_ptr](https://en.cppreference.com/w/cpp/memory/weak_ptr)

[C++ make_shared使用](https://blog.csdn.net/duringsummer/article/details/122524446)

[C++11 shared_ptr智能指针](https://c.biancheng.net/view/7898.html)

[C++ 智能指针(四) std::weak_ptr](https://blog.csdn.net/weixin_43130747/article/details/128840874)

[【C++11】 之 std::unique_ptr 详解](https://blog.csdn.net/lemonxiaoxiao/article/details/108603916)

[如何：创建和使用 shared_ptr 实例](https://learn.microsoft.com/zh-cn/cpp/cpp/how-to-create-and-use-shared-ptr-instances?view=msvc-170)

[C++动态内存：智能指针、动态数组](https://segmentfault.com/a/1190000005942237)

