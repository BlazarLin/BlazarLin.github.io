---
title: c++异常捕获
categories: 
- C++编程
tags: 
- c++
- 异常捕获
- pdb
---

## 一、`try` 与`__try`的区别

Release方式下如果选择了编译器代码优化选项，则VC编译器会去搜索try块中的代码， 如果没有找到throw代码， 他就会认为try catch结构是多余的， 给优化掉。 这样造成在Release模式下，上述代码中的异常不能被捕获，从而迫使程序弹出错误提示框退出。

https://stackoverflow.com/questions/7049502/c-try-and-try-catch-finally

## 二、捕获方法

### 1. 全局捕获A

```c++
// 单独用这种方法能捕获到异常，但是程序仍然自行退出!!
::SetUnhandledExceptionFilter(unKnownExceptionFilterWrapper);
```

qt会提示Qt has caught an exception thrown from an event handler. Throwing
exceptions from an event handler is not supported in Qt.
You must not let any exception whatsoever propagate through Qt code.
If that is not possible, in Qt 5 you must at least reimplement
QCoreApplication::notify() and catch all exceptions there.

### 2. 全局捕获B

   基于上述方法的提示，重载QApplication的notify事件可以捕获到信号或控件的异常

   ```c++
   class MyQApplication :public QApplication
   {
   public:
   	MyQApplication(int& argc, char** argv, int = ApplicationFlags) :
   		QApplication(argc, argv, ApplicationFlags)
   	{
   
   	};
   private:
   	virtual bool notify(QObject* receiver, QEvent* e)
   	{
   		__try
   		{
   			return __super::notify(receiver, e);
   		}
   		__except (unKnownExceptionFilter(GetExceptionInformation(), GetExceptionCode()))
   		{
   			printf("\n\nException-Handler called\n\n\n");
   		}
   		return false;
   	}
   };
   ```

   在__except事件中，进行异常事件的处理

### 3. 局部捕获

使用lambda函数对目标函数区域进行异常捕获

```c++
// 预先定义
int caughtSEHException(std::function<int()> func)
{
    __try {
		return std::forward <Function >(func)();
	}
	__except (unKnownExceptionFilter(GetExceptionInformation(), GetExceptionCode()))
	{
		return -1;
	}

	return 0;
}

// 使用时
auto result = caughtSEHException([&]()->int {
    
    // 目标执行代码
    
    return 1; });
if (-1 == result)
{
    // 出现异常
}
```

由于程序大部分是多线程，若要溯源哪个线程导致的异常，需要记录下执行的线程号，在异常捕获时对比线程ID确认是由哪个线程触发导致。



## 三、输出异常位置

### 方法一：

使用Win提供的`SymInitialize`与`StackWalk64`方法遍历堆栈

```c++
// 得到函数名 
SymGetSymFromAddr64(hProcess, sf.AddrPC.Offset, NULL, pSymbol);
// 得到文件名和所在的代码行  
SymGetLineFromAddr64(hProcess, sf.AddrPC.Offset, &dwLineDisplacement, &lineInfo);
// 得到模块名
SymGetModuleInfo64(hProcess, sf.AddrPC.Offset, &moduleInfo)
```



### 方法二：

引用github项目[StackWalker - Walking the callstack](https://github.com/JochenKalmbach/StackWalker#stackwalker---walking-the-callstack)，参考Main示例，重载`StackWalker`类的`OnOutput函数`实现信息输出到目标文件。

只需要导入StackWalker.cpp与StackWalker.h两份文件到自己的工程中。

例如：

```cpp
class StackWalkerToConsole : public StackWalker
{
public:
#ifndef _DEBUG
	StackWalkerToConsole() :StackWalker(
		StackWalkOptions::OptionsAll,
		QString(qApp->applicationDirPath() + "/pdb/").toLocal8Bit().data()
	) { };
#else
	StackWalkerToConsole() :StackWalker(
		StackWalkOptions::OptionsAll
	) { };
#endif // _DEBUG

protected:
	virtual void OnOutput(LPCSTR szText) { 
		qWarning() << szText;
	}
};
```

在异常出现时进行输出：

```c++
StackWalkerToConsole sw; // output to the console
sw.ShowCallstack(GetCurrentThread(), pExptInfo->ContextRecord);
```



## 四、保存DMP文件

保存DMP文件的目的是为了取回复现，方便发现bug

使用win提供的`MiniDumpWriteDump`方法，写入当前进程与线程的信息，后续使用VS运行产生的`*.dmp`文件，配合程序发布同版本的DPB文件，即可复现异常代码位置。

如何复现bug位置参考[c++使用pdb信息复现崩溃位置](https://www.blazar.fun/2023/06/17/c++%E4%BD%BF%E7%94%A8pdb%E4%BF%A1%E6%81%AF%E5%A4%8D%E7%8E%B0%E5%B4%A9%E6%BA%83%E4%BD%8D%E7%BD%AE/)

