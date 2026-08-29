---
title: c++线程用法
categories: 
- C++编程
tags: 
- c++
- 线程
---

## 当前最常用的几个线程库

1、c++官方`<thread>`，使用的函数类`std::thread`
2、QT的QThread类
3、Windows API `::CreateThread`

## std::thread

### lambda写法
```c++
int nInputValue1 = 10;//输入的形参1
int nInputValue2 = 20;//输入的形参2
// 线程函数声明
std::thread testCppThread([&](int nVal1,int nVal2) 
{
    // 逻辑代码
    for (int i = 0; i < nVal1; i++)
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
}, nInputValue1, nInputValue1);
testCppThread.detach();		// 后台执行，立即执行后续代码
// testCppThread.join();	// 阻塞执行，线程执行结束再执行后续代码
```

### 函数指针写法

#### 普通函数
```c++
void functionTest() {
	int times = 5;
	static int all_num = 0;
	while (true)
	{
		std::this_thread::sleep_for(std::chrono::milliseconds(100));
		all_num++;
		qInfo() << QString("sum is %1").arg(all_num);
		if (!(--times)) {
			break;
		}
	}
}

std::thread testCppThread(&functionTest);
testCppThread.detach();

```

#### 类函数
需要额外传入类的实例指针
```c++
void ClassA::threadWayCPPWorker()
{
    ;
}
void ClassA::testThread()
{
    std::thread testCppThread(&ClassA::threadWayCPPWorker, this);
    testCppThread.detach();
}

```
###  线程安全

当一个变量被多个线程同时操作时，为了保证其在同一个时期被控制的唯一性，需要使用原子型变量或线程锁予以防护。

案例：开5个线程对某变量进行0-100的叠加，正确的结果是4950*5=24750。

错误案例
```c++
// 错误案例
static int nAddSum = 0;
// 叠加测试
int _numThead = 5;
int _range = 100;
for (int j = 0; j < _numThead; j++)
{
    std::thread th1([&](int nID,int nTimes) {
        for (int i = 0; i < nTimes; i++)
        {
            nAddSum += i;
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        qInfo() << QString("<%1>累加结束,总和%2").arg(nID).arg(nAddSum);
    },j, _range);
    th1.detach();
}
```
运行程序后发现每次的结果都不一致，是因为变量`nAddSum`在多个线程被同时操作。为了解决同时这个问题，可以使用原子型变量或增加线程锁。

#### 原子变量
```c++
#include <atomic>

std::atomic<int> nSense1;
std::atomic<bool> bSense1;
```

```c++
// static int nAddSum = 0;
static std::atomic<int> nAddSum = 0;// ---------------变化
// 叠加测试
int _numThead = 5;
int _range = 100;
for (int j = 0; j < _numThead; j++)
{
    std::thread th1([&](int nID,int nTimes) {
        for (int i = 0; i < nTimes; i++)
        {
            nAddSum += i;
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        qInfo() << QString("<%1>累加结束,总和%2").arg(nID).arg(nAddSum);
    },j, _range);
    th1.detach();
}
```

#### 线程锁
```c++
static int nAddSum = 0;
static std::mutex _mutex;// ---------------变化
// 叠加测试
int _numThead = 5;
int _range = 100;
for (int j = 0; j < _numThead; j++)
{
    std::thread th1([&](int nID,int nTimes) {
        for (int i = 0; i < nTimes; i++)
        {
            std::lock_guard<std::mutex> lg(_mutex);// ---------------变化
            nAddSum += i;
            //std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        qInfo() << QString("<%1>累加结束,总和%2").arg(nID).arg(nAddSum);
    },j, _range);
    th1.detach();
}
```


## QThread

QThread的使用模式与std::thread有些不同，可以理解QThread为一个基类，需要重载其方法来实现，可以参考官方开发者的语录：[You’re doing it wrong…](https://www.qt.io/blog/2010/06/17/youre-doing-it-wrong)。

QThread对象管理程序中的一个控制线程。QThreads在run()中开始执行。默认情况下，run()通过调用exec()启动事件循环，并在线程内运行Qt事件循环。

主要的两种使用方法，[QObject::moveToThread()](https://doc.qt.io/qt-5/qobject.html#moveToThread)与重写run()

### 创建线程

####  moveToThread

使用官方提供的demo做说明:

使用QObject::moveToThread()将工作对象移动到线程中来使用它们，Worker槽内的代码将在单独的线程中执行。还可以自由地将Worker的插槽连接到任何信号，来自任何对象，任何线程。由于一种称为排队连接的机制，跨不同线程连接信号和插槽是安全的。

```c++
class Worker : public QObject
{
    Q_OBJECT

public slots:
    void doWork(const QString &parameter) {
        QString result;
        /* ... here is the expensive or blocking operation ... */
        emit resultReady(result);
    }

signals:
    void resultReady(const QString &result);
};

class Controller : public QObject
{
    Q_OBJECT
    QThread workerThread;
public:
    Controller() {
        Worker *worker = new Worker;
        worker->moveToThread(&workerThread);
        connect(&workerThread, &QThread::finished, worker, &QObject::deleteLater);
        connect(this, &Controller::operate, worker, &Worker::doWork);
        connect(worker, &Worker::resultReady, this, &Controller::handleResults);
        workerThread.start();
    }
    ~Controller() {
        workerThread.quit();
        workerThread.wait();
    }
public slots:
    void handleResults(const QString &);
signals:
    void operate(const QString &);
};

auto controller = new Controller();
emit controller->operate("Do Work");// 触发一次，干一次活。
```



#### 继承QThread重写run()

另一种使代码在单独线程中运行的方法是创建QThread的子类并重新实现run()，该示例中，线程将在run函数返回后退出。除非调用exec()，否则线程中**不会运行任何事件循环**。

```c++
class WorkerThread : public QThread
{
    Q_OBJECT
    void run() override {
        QString result;
        /* ... here is the expensive or blocking operation ... */
        emit resultReady(result);
    }
signals:
    void resultReady(const QString &s);
};

void MyObject::startWorkInAThread()
{
    WorkerThread *workerThread = new WorkerThread(this);
    connect(workerThread, &WorkerThread::resultReady, this, &MyObject::handleResults);
    connect(workerThread, &WorkerThread::finished, workerThread, &QObject::deleteLater);
    workerThread->start();
}
```

> 重要的是要记住，QThread实例存在于实例化它的旧线程中，而不是在调用run()的新线程中。这意味着QThread的所有排队槽和调用的方法都将在旧线程中执行。因此，希望在新线程中调用槽的开发人员必须使用**worker-object**方法;新的插槽不应该直接实现到子类QThread中。与排队槽或调用的方法不同，直接在QThread对象上调用的方法将在调用该方法的线程中执行。

### 使用线程

> 当线程[started](https://doc.qt.io/qt-5/qthread.html#started)()和[finished](https://doc.qt.io/qt-5/qthread.html#finished)()时，QThread将通过信号通知您，或者您可以使用[isFinished](https://doc.qt.io/qt-5/qthread.html#isFinished)()和[isRunning](https://doc.qt.io/qt-5/qthread.html#isRunning)()来查询线程的状态。您可以通过调用[exit](https://doc.qt.io/qt-5/qthread.html#exit)()或[quit](https://doc.qt.io/qt-5/qthread.html#quit)()来停止线程。在极端情况下，您可能希望强制[terminate](https://doc.qt.io/qt-5/qthread.html#terminate)()正在执行的线程。然而，不鼓励这种危险的做法。

#### start

开始执行线程

#### quit

退出的是事件循环，不是立即退出该线程，退出实践循环后，对应的`Worker`也被析构了，因为`connect(&workerThread, &QThread::finished, worker, &QObject::deleteLater);`

![image-20230701105759722](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_quit.png)

#### wait

阻塞外部线程，直到该线程执行完毕再继续执行外部线程。

#### exit

告诉线程的事件循环以一个返回代码退出。调用此函数后，线程离开事件循环，并从对QEventLoop::exec()的调用中返回。QEventLoop::exec()函数返回returnCode为0表示成功，任何非零值表示错误。

效果等同于quit

![image-20230701110330493](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_exit.png)

## ::CreateThread