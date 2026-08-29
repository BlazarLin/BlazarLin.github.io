---
title: QT源码调试
categories: 
- QT编程
tags: 
- c++
- QT
- 调试
---

# QT源码调试

## 方法1
打开QT安装目录下`C:\Qt\Qt5.14.2`的维护工具，`MainTenanceTool.exe`
在设置中点击资料档案库，添加对应版本的地址，我的是`QT5.14.2`

![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_maintain.png)

```
https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5142_src_doc_examples/
https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw/
https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5142/
```

选择添加或移除组件，勾选`QT Debug Infomation Files`，下一步安装即可。
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_debuginfo.png)

但是，一些QT版本不支持在线下载，维护工具内没有下载`QT Debug Infomation Files`选项，则需要使用另一种手动下载配置的方法。

## 方法2

手动下载[QT Download](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5111/qt.qt5.5111.win64_msvc2017_64/)对应版本的PDB压缩包，

![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_basefile.png)

在VS内添加源码路径

![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_pdb.png)

添加符号调试

![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_srcpath.png)

断点测试进入show函数

![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_showfunc.png)

大功告成

参考：
[VS2017调试Qt源码](https://ifmet.cn/posts/134fdafb/)
[qt5.12调试信息（pdb文件）安装](https://blog.simbot.net/2019/07/28/qt-debug-symbols/)