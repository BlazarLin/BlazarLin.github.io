---
title: WIN&Ubuntu双系统使用手册
categories: 
- 编程工具
tags: 
- Ubuntu
- 系统运维
---
# WIN&Ubuntu双系统使用手册

## 一、需要资源

- U盘一个（提前备份数据）
- Ubuntu 20.04 LTS 镜像
- Rufus–1008.05kb 启动工具
    - 下载地址：链接: [下载链接](https://pan.baidu.com/s/1hmMkLOdCj26dusJU7-JrBQ) 密码: om26
    

## 二、window设置

### 1、分区

确认硬盘上有空闲区域



![Untitled](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/Untitled.png)

若无，则使用一下方法压缩出已有硬盘的空间

- 压缩硬盘空间
  
    分出一个空的区域给ubuntu系统做存储。
    
    在桌面上，点击计算机图标（右键）–> 管理 --> 找到磁盘管理，之后找一个比较大的硬盘分区点击一下
    
    ![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/d8b77d50bc7bcbae16c5891320a3ed51.png)
    
    比如我点了“学习资料”，右键选择压缩卷。
    
    ![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/620f4b0c945218110483fb91c93725a5.png)
    
    输入需要压缩的空间，就能得到一个对应的空余空间用来当做ubuntu系统盘。
    

### 2、启动盘制作

打开Rufus制作工具

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/de37d5fea358ca817c7d406b4f35df72.png)

主要是选择好对应的iso镜像，开始制作启动盘。

如果电脑使用U盘启动无法识别该U盘，设置分区类型MBR改到GPT。

## 三、ubuntu安装

1、进入Bios设置U盘启动

2、进入后选择ubuntu

安装要注意一个点：安装类型选择其他选项。

选择安装类型，这里我们自定义安装，选择其他选项。如果不想折腾也可以简单选择第一个选项。

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/f2874fc6c9709383c97d926268cec154.png)

**分区，这是最重要的一点**，前面我们预留了硬盘空间这里就用上了，我们点击空余空间，点 + 号新建分区。

这里我们要分四个区域，分别是

- / 根目录整个系统的大区域一般15G以上。
- /boot 启动目录，开机启动所需目录。（200M-2G）
- swap 交换空间，一般和内存一样大。
- /home 家目录，就是我们自己存放用户数据的目录。一般有多少给多少

推荐`/`与 `/home`五五开

![Untitled](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/Untitled%201.png)

/ 根目录我分了 286GB

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/91f775d488246cc8ee6d4cf886a48063.png)

swap 交换空间为16GB

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/b07078a93332e7a576e3060429167d34.png)

/boot 启动目录我分了2GB

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/3318d88b9135420962da916c21788245.png)

/home 我设置了286GB

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/027635c1d693ea1803afc361e2bbbfc1.png)

## 四、设置开机界面显示win10和Ubuntu选项

1、进入ubuntu系统，左下角查看所有应用，打开终端：

2、用以下命令打开boot下的grub配置文件（注意命令中共两个空格，并且回车后会让你输入密码，不显示无所谓，正确输入密码并回车即可）

```
sudo gedit /boot/grub/grub.cfg

```

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/e1e598372b884df3adc6bca5bf780370.png)

3、在grub配置文件中右上角利用查找功能，输入windows查找，找到win10引导菜单选项（大概在200多行），然后复制win10引导菜单名称（含单引号），然后关闭grub配置文件：

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/b5a954bf11474332b7564afc017e34f3.png)

4、回到终端继续输入以下命令来打开etc下的grub文件：

```
sudo gedit /etc/default/grub

```

5、找到GRUB_DEFAULT，并将它的值设置为我们刚刚复制的win10引导菜单名称（含单引号），然后保存此grub文件，再关闭

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/cf7eab35f6864d8183c82577c0e3062e.png)

6、回到终端，继续输入以下命令以更新grub菜单：

```
sudo update-grub

```

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/0d9ed31acd6c46b3aff055425aaa3034.png)

7、输入完命令并回车后，等待完成配置，待命令行为可编辑的格式后方可关闭。

8、重启电脑，`进入BIOS设置，把Ubuntu设置为第一启动项`，（进入BIOS参考前面的`〇 - Plus：如何进入BIOS`，具体设置根据自己的电脑品牌搜教程，一般是在Boot栏目下，把Ubuntu排序在最上面，按F10保存即可）保存后退出。
 例如我的是这样的：

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/230e97c59f604f67bc79b2b8a5c2fa97.jpg)

根据提示操作即可。

重启后会发现开机启动选项中，虽然ubuntu在第1位置，但是当前高亮的（被选择的）是windows系统，也就是说以后按下开机键你不再需要进行别的操作即可进入windows系统；如果想进入ubuntu系统，只需要向上选择ubuntu并回车即可：

![](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/WIN%26Ubuntu%E5%8F%8C%E7%B3%BB%E7%BB%9F%E4%BD%BF%E7%94%A8%E6%89%8B%E5%86%8C/f6a6bedec5004e65ad8bcb532fac9193.jpg)