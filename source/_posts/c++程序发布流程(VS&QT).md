---
title: c++程序发布流程(VS&QT)
categories: 
- 编程工具
tags: 
- QT
- 部署配置
---

一、QT环境

- 打开终端`Qt 5.11.1 64-bit for Desktop (MSVC 2017)`或系统的`cmd`
- 切换到程序运行盘符`:E`，cd到要打包exe的目录下
- 执行命令 `windeployqt XXX.exe`，则会生成QT环境；

在程序运行目录下

二、其他环境

- 打开终端`适用于 VS 2017 的 x64 本机工具命令提示`
- 切换到程序目录，执行命令`dumpbin /IMPORTS XXX.exe>output.txt`导出依赖；
- 使用`everything`将查找到的*.dll拷贝到程序目录



