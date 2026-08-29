---
title: c++使用pdb信息复现崩溃位置
categories: 
- 编程工具
tags: 
- c++
- pdb
- 异常捕获
---
## c++使用pdb信息复现崩溃位置


条件：发布程序时保留对应版本的pdb文件

复现步骤：

1、拷贝崩溃产生的dmp文件

![dmpfiles](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/dmpfiles.png)

2、使用vs2017打开dmp，这里能够大致看到崩溃信息

![dmpfiles](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/vsdmp.png)

3、在设置符号调试内，勾选Microsoft符号调试器与软甲同版本的pdb文件列表，且要加载排除模块外的所有模块，配置好后点击确认

![dmpfiles](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/vsSetting.png)



4、创建崩溃程序的**同路径同版本程序**，在右侧操作栏，点击使用仅限本机进行调试；

工程建立新分支**回退到崩溃程序的相同版本**(若不进行此操作，复现的崩溃位置不正确)；

(首次加载符号需要从微软自动下载pdb文件，科学上网加快速度)等待后就可以看到崩溃位置源码与堆栈信息；