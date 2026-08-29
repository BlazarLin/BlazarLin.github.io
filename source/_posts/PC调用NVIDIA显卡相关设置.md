---
title: PC调用NVIDIA显卡相关设置
mathjax: true
categories: 
- 编程工具
tags:
- 部署配置
---

# 一、操作步骤

1、 移动依赖文件至<C:\Windows\System32>

2、 安装显卡驱动

3、 解压视觉软件至<C:\PA\Release>

4、 设置页面文件大小与显卡高性能设置

# 二、设置页面文件大小

在自主训练软件下需要虚拟内存，需要进行以下设置。

1、 右击此电脑，点击高级系统设置；
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/nv_gaojixitongshezhi.png)



2、 在弹出的系统属性中，选择高级，(性能)设置；
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/nv_xitongshuxing.png)

3、 在弹出的性能选项中，选择高级，点击(虚拟内存)更改；
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/nv_xingnengxuanxiang.png)

4、 不勾选自动管理所有驱动器的分页大小，**依次点击每个盘符，选择为系统管理的大小**，并单击设置，最后点击确认。若提示电脑需要重启则重新启动。
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/nv_xitongguanlidaxiao.png)

 

# 三、安装显卡驱动，设置显卡高性能

要求系统在固定时间内实时响应，但是当前win10系统下，会自动根据负载调整CPU和GPU运行频率，导致算法执行时间波动非常大。

5、 点击win，搜索NVIDIA Control Panel
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/nv_NVIDIACP.png)

6、 通过预览调整图像设置 - 使用我的优先选择 - 侧重于 - 性能 - 应用，保存设置
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/nv_xingnengyouxian.png)

7、 管理 3D 设置：将电源管理模式设置为最高性能优先，点击“应用”保存设置生效。
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/nv_zuigaoxingneng.png)

8、 验证方式：通过nvidia-smi命令查看GPU性能模型，确认工作在P0或P2模式下，P的数字越小性能越高。
![descript](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/nv_nvidia-smi.png)