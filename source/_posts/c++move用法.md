---
title: c++move用法
categories: 
- C++编程
tags: 
- c++
- STL源码分析
---

## 1、区分左值与右值的区别

左值与右值的根本区别在于是否允许取地址&运算符获得对应的内存地址。
变量可以取地址，所以是左值，但是常量和临时对象等不可以取地址，所以是右值。

左值是表达式结束后依然存在的持久对象(代表一个在内存中占有确定位置的对象)。
右值是表达式结束时不再存在的临时对象(不在内存中占有确定位置的表达式）。

所有的具名变量或者对象都是左值，而右值不具名。

对表达式取地址，如果能，则为左值，否则为右值。

常见的右值：“abc",123等都是右值。

右值引用，可以延长右值的生命周期

```c++
int&& i = 123;
int&& j = std::move(i);
int&& k = i;//编译不过，这里i是一个左值，右值引用只能引用右值
```



## 2、Move

### 用法1 转移所有权

​		将快要销毁的对象转移给其他变量，这样可以继续使用这个对象，而不必再创建一个一样的对象，省去了创建新的一样内容的对象，也就提高了性能。

```c++
// move example
#include <utility>      // std::move
#include <iostream>     // std::cout
#include <vector>       // std::vector
#include <string>       // std::string

int main () {
  std::string foo = "foo-string";
  std::string bar = "bar-string";
  std::vector<std::string> myvector;

  myvector.push_back (foo);                    // copies
  myvector.push_back (std::move(bar));         // moves(移动语义，避免拷贝，从而提升程序性能)

  std::cout << "myvector contains:";
  for (std::string& x:myvector) std::cout << ' ' << x;
  std::cout << '\n';

  return 0;
}
```



### 用法2 改变所有者

​		对象的管理问题：编程语言的move是改变物体(值）的所有权，而物体（值）在内存中没有变动过(存储在堆里那部分数据没有变动，在栈上的数据被拷贝了)。

```c++
class Array {
public:
	Array() {}
	
	// 深拷贝构造
	Array(const Array & temp_array) {
		size_ = temp_array.size_;
		data_ = new unsigned char[size_];
		std::memcpy(data_, temp_array.data_, size_);
		/*for (int i = 0; i < size_; i++) {
			data_[i] = temp_array.data_[i];
		}*/
	}

	// 深拷贝赋值
	Array& operator=(const Array& temp_array) {
		delete[] data_;
		size_ = temp_array.size_;
		data_ = new unsigned char[size_];
		std::memcpy(data_, temp_array.data_, size_);
		/*for (int i = 0; i < size_; i++) {
			data_[i] = temp_array.data_[i];
		}*/
	}

	// 优雅 
    // std::move(a) 进此函数 避免拷贝
	Array(Array&& temp_array) {
		data_ = temp_array.data_;
		size_ = temp_array.size_;
		// 为防止temp_array析构时delete data，提前置空其data_      
		temp_array.data_ = nullptr;
	}


public:
	unsigned char* data_;
	int size_;
};

cv::Mat matImage = cv::imread("230814images/Image_20230814163826944.bmp", cv::IMREAD_COLOR);
Array a;
a.data_ = matImage.data;
a.size_ = matImage.rows * matImage.cols * matImage.channels();
int size2 = matImage.rows * matImage.step;

Array c = a;

// 左值a，用std::move转化为右值
Array b(std::move(a));
```



### 用法3 高效变量赋值

将vector B赋值给另一个vector A，如果是拷贝赋值，那么显然要对B中的每一个元素执行一个copy操作到A，如果是移动赋值的话，只需要将指向B的指针拷贝到A中即可，若vector内元素复杂，数量大，则凸显出的性能优化则更加明显。

下面对比拷贝赋值与移动语义的耗时

```c++
int nTestTimes = 100;
double dAllTimes = 0;
for (int i = 0; i < nTestTimes; i++)
{
    std::vector<int> vb(100, 2);

    auto start1 = std::chrono::steady_clock::now();
    // 此处用move就不会对vb中已有元素重新进行拷贝构造然后再放到va中
    std::vector<int> va = std::move(vb);
    //std::vector<int> va = vb;
    auto end1 = std::chrono::steady_clock::now();
    auto fTimeInfer = std::chrono::duration<double, std::milli>(end1 - start1).count();
    dAllTimes += fTimeInfer;
}
double dOneTime = dAllTimes / nTestTimes;
std::cout << "allTime:" << dAllTimes << "oneTime:" << dOneTime << std::endl;

// >>> allTime:0.2631，oneTime:0.002631 移动语义
// >>> allTime:0.5511，oneTime:0.005511 拷贝

```

可以看出，时间使用移动语义相比拷贝时间少了一半。

## 3、万能引用

```c++
/// 测试1
template<typename T>
void funcTest(T& param) {
	std::cout << param << std::endl;
}

/// 测试2
template<typename T>
void funcTest2(T& param) {
	std::cout << "传入的是左值" << std::endl;
}
template<typename T>
void funcTest2(T&& param) {
	std::cout << "传入的是右值" << std::endl;
}

/// 测试3
template<typename T>
void funcTest3(T&& param) {
	std::cout << param << std::endl;
}

int main()
{
    std::cout << "Hello World!\n";

	// 万能引用
	if (1)
	{
		// 常规左值引用
		int num = 2023;
		funcTest(num);// 正确
		// funcTest(2023);// 错误，因为参数为左值引用，却传入一个右值

		// 左值模板函数与右值模板函数
		funcTest2(num);
		funcTest2(2023);

		// 万能引用
		funcTest3(num);
		funcTest3(2023);
	}
}
```

测试1定义了左值引用的模板函数，使用常量2023作为形参输入就导致报警；测试2定义了2个模板函数；测试3使用万能引用，针对输入变量类型自动推理出左值或右值，需要注意：**只有发生类型推导的时候，T&&才表示万能引用（如模板函数传参就会经过类型推导的过程）**



## 4、拓展

完美转发`std::forward`
引用折叠



参考：
https://juejin.cn/post/7192171206030819385
https://en.cppreference.com/w/cpp/utility/move
https://cloud.tencent.com/developer/article/1901799
https://www.cnblogs.com/shadow-lr/p/Introduce_Std-move.html
https://zhuanlan.zhihu.com/p/94588204