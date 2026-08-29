---
title: Ubuntu系统操作
categories: 
- 编程工具
tags: 
- Ubuntu
- 系统运维
---

# Ubuntu系统操作

# 制作镜像软件

rufus-4.9p.exe

下载地址：[https://rufus.ie/downloads/](https://rufus.ie/downloads/)

说明书：[https://rufus.ie/zh/](https://rufus.ie/zh/)

镜像地址

https://mirrors.aliyun.com/ubuntu-releases/22.04/

https://mirrors.aliyun.com/ubuntu-releases/24.04.2/?spm=a2c6h.25603864.0.0.2b8c4ddad1dR3Q

# 分区建议

单系统无需设置，若已经存在win系统，需要在另一个磁盘上安装ubuntu，则需要该步骤

简易模式

参考：

![image.png](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/Ubuntu%E7%B3%BB%E7%BB%9F%E6%93%8D%E4%BD%9C/image.png)

实际空间分配，单独安装在一个独立的2T硬盘上

| 区块 | 类型 | 容量 |
| --- | --- | --- |
| /boot | Exj4 逻辑分区 | 1024MB |
| /tmp | Exj4 逻辑分区 | 4096MB |
| / | Exj4 主分区 | 102400MB(100GB) |
| /home | Exj4 逻辑分区 | 819200MB(800GB) |

失败记录

自定义分区配置只有efi分区无boot分区时，在安装时报错：**`执行‘grub-install/dev/nvmeOn1p5‘失败。这是一个致命错误。` ，`unable to install grub in /dev/nvme0n1`**

thinkbook 16+ 安装20.04版本ubuntu一直安装不上wifi，尝试过内核更新过也无效，后续换成22.04

ref:

https://cloud.tencent.com/developer/article/2062320

[https://blog.csdn.net/NeoZng/article/details/122779035](https://blog.csdn.net/NeoZng/article/details/122779035)

https://blog.csdn.net/wxd1233/article/details/120335134

# 字体太小眼睛要瞎了

安装 gnome 

`sudo apt install gnome-tweaks`

打开gnome-tweak-tool。

在左侧菜单中选择“字体”，然后你可以调整字体大小。

配置搜狗输入法：[https://shurufa.sogou.com/linux/guide](https://shurufa.sogou.com/linux/guide)

终端样式

https://www.haoyep.com/posts/zsh-config-oh-my-zsh/

连接到局域网内的win主机

smb://*服务器*ip地址

# qt配置

## Win

vs转qt工程

右键vs项目，找到Create Basic .pro File

![image.png](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/Ubuntu%E7%B3%BB%E7%BB%9F%E6%93%8D%E4%BD%9C/image1.png)

若没有找到，则安装 LEGACY Qt Visual Studio Tools 与 Qt VSCMake Tools，同时禁用原先的Qt Visual Studio Tools

![image.png](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/Ubuntu%E7%B3%BB%E7%BB%9F%E6%93%8D%E4%BD%9C/image2.png)

vs 插件卸掉了安装不上的问题，去安装目录`C:\Users\Administrator\AppData\Local\Microsoft\VisualStudio\16.0_ad6ec444\Extensions`下找到对应的文件夹删干净就行

[https://blog.csdn.net/Kepler11/article/details/120229355](https://blog.csdn.net/Kepler11/article/details/120229355)

Ubuntu

`sudo apt-get install gcc g++ clang`

`sudo apt-get install build-essential qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools`

`sudo apt-get install **qtbase5-examples** qtcreator` 

## Opencv环境

非源码编译

`sudo apt-get install libopencv-dev libopencv-contrib-dev`   

检查是否安装成功

- 命令行查看

```bash
❯ apt-cache policy libopencv-dev
libopencv-dev:
  已安装：4.5.4+dfsg-9ubuntu4
  候选： 4.5.4+dfsg-9ubuntu4
  版本列表：
 *** 4.5.4+dfsg-9ubuntu4 500
        500 http://cn.archive.ubuntu.com/ubuntu jammy/universe amd64 Packages
        100 /var/lib/dpkg/status
     
# 查看所有cv链接库
❯ pkg-config --libs opencv4
-lopencv_stitching -lopencv_alphamat -lopencv_aruco -lopencv_barcode -lopencv_bgsegm -lopencv_bioinspired -lopencv_ccalib -lopencv_dnn_objdetect -lopencv_dnn_superres -lopencv_dpm -lopencv_face -lopencv_freetype -lopencv_fuzzy -lopencv_hdf -lopencv_hfs -lopencv_img_hash -lopencv_intensity_transform -lopencv_line_descriptor -lopencv_mcc -lopencv_quality -lopencv_rapid -lopencv_reg -lopencv_rgbd -lopencv_saliency -lopencv_shape -lopencv_stereo -lopencv_structured_light -lopencv_phase_unwrapping -lopencv_superres -lopencv_optflow -lopencv_surface_matching -lopencv_tracking -lopencv_highgui -lopencv_datasets -lopencv_text -lopencv_plot -lopencv_ml -lopencv_videostab -lopencv_videoio -lopencv_viz -lopencv_wechat_qrcode -lopencv_ximgproc -lopencv_video -lopencv_xobjdetect -lopencv_objdetect -lopencv_calib3d -lopencv_imgcodecs -lopencv_features2d -lopencv_dnn -lopencv_flann -lopencv_xphoto -lopencv_photo -lopencv_imgproc -lopencv_core

```

自定义SO载入失败：ubuntu只带SO名字，没加绝对路径时，在/usr/lib下加载，而不是类似win在程序运行目录下加载，需要绝对路径
static QLibrary flawDll(_exePath2+"/libFlawDetect.so");

源码编译

todo

## demo工程

- QT 工程调用opencv显示图片

新建一个新的pro

![image.png](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/Ubuntu%E7%B3%BB%E7%BB%9F%E6%93%8D%E4%BD%9C/image3.png)

```bash
QT       += core gui

INCLUDEPATH += /usr/include \
                /usr/include/opencv4 \
                /usr/include/opencv4/opencv2

LIBS += -L/usr/lib/x86_64-linux-gnu -lopencv_stitching -lopencv_alphamat -lopencv_aruco -lopencv_barcode -lopencv_bgsegm -lopencv_bioinspired -lopencv_ccalib -lopencv_dnn_objdetect -lopencv_dnn_superres -lopencv_dpm -lopencv_face -lopencv_freetype -lopencv_fuzzy -lopencv_hdf -lopencv_hfs -lopencv_img_hash -lopencv_intensity_transform -lopencv_line_descriptor -lopencv_mcc -lopencv_quality -lopencv_rapid -lopencv_reg -lopencv_rgbd -lopencv_saliency -lopencv_shape -lopencv_stereo -lopencv_structured_light -lopencv_phase_unwrapping -lopencv_superres -lopencv_optflow -lopencv_surface_matching -lopencv_tracking -lopencv_highgui -lopencv_datasets -lopencv_text -lopencv_plot -lopencv_ml -lopencv_videostab -lopencv_videoio -lopencv_viz -lopencv_wechat_qrcode -lopencv_ximgproc -lopencv_video -lopencv_xobjdetect -lopencv_objdetect -lopencv_calib3d -lopencv_imgcodecs -lopencv_features2d -lopencv_dnn -lopencv_flann -lopencv_xphoto -lopencv_photo -lopencv_imgproc -lopencv_core

CONFIG += c++14

SOURCES += \
    mainRun.cpp

```

新建一个测试cpp，若能显示图像则环境配置成功

```cpp
#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

int main(int agrc, char** agrv)
{
    Mat img=imread("/home/lcq/Code/images/RFID.bmp");
    // Mat img=imread("test.bmp");
    imshow("test",img);
    waitKey(0);
    return 0;
}

```

1、遇到错误 libprotobuf.so.23: error adding symbols: DSO missing from command line

重新安装libprotobuf-dev：`sudo apt-get install --reinstall libprotobuf-dev`

**2、解决 undefined reference to cv::imread(std::__cxx11::basic_string＜char, std::char_traits＜char＞,....**

修改*.pri内链接opencv库的方式

```cpp
// 原先
LIBS += -L/usr/lib/x86_64-linux-gnu/libopencv_*

// 修改后
LIBS += -L/usr/lib/x86_64-linux-gnu -lopencv_stitching -lopencv_alphamat -lopencv_aruco -lopencv_barcode -lopencv_bgsegm -lopencv_bioinspired -lopencv_ccalib -lopencv_dnn_objdetect -lopencv_dnn_superres -lopencv_dpm -lopencv_face -lopencv_freetype -lopencv_fuzzy -lopencv_hdf -lopencv_hfs -lopencv_img_hash -lopencv_intensity_transform -lopencv_line_descriptor -lopencv_mcc -lopencv_quality -lopencv_rapid -lopencv_reg -lopencv_rgbd -lopencv_saliency -lopencv_shape -lopencv_stereo -lopencv_structured_light -lopencv_phase_unwrapping -lopencv_superres -lopencv_optflow -lopencv_surface_matching -lopencv_tracking -lopencv_highgui -lopencv_datasets -lopencv_text -lopencv_plot -lopencv_ml -lopencv_videostab -lopencv_videoio -lopencv_viz -lopencv_wechat_qrcode -lopencv_ximgproc -lopencv_video -lopencv_xobjdetect -lopencv_objdetect -lopencv_calib3d -lopencv_imgcodecs -lopencv_features2d -lopencv_dnn -lopencv_flann -lopencv_xphoto -lopencv_photo -lopencv_imgproc -lopencv_core
// 所有cv相关链接库根据pkg-config --libs opencv4命令获取
```

3、依赖问题

若库安装的位置不在`/usr/local/lib` (相当于win中`C:\Windows\System32`)内，则需要将库软链接到运行程序目录下，或者在`/etc/ld.so.conf.d/libc.conf` (相当于win中环境变量配置)内加入编译库的位置；

https://blog.csdn.net/weixin_44796670/article/details/115900538

cmake+qt配置opencvhttps://zhuanlan.zhihu.com/p/681817070

# qmake语法

.pro工程文件包含qmake构建应用、库、插件的所有必须信息。

```cpp
HEADERS += ./flawDetect.h \
    ./flawdetect_global.h \
    ./resource.h \
    ./_contours.h
SOURCES += ./flawDetect.cpp \
    ./_contours.cpp

QT      += core gui widgets
CONFIG  += c++17
DEFINES += QTCBuild
DEFINES += BUILD_STATIC
```

常用简介

```cpp
136、QMAKE_POST_LINK

指定将 TARGET 链接在一起后要执行的命令。这个变量也不是 mally 为空，因此不执行任何操作。注意：这个变量对 Xcode 项目没有影响。
c常配合拷贝语句使用
SrcPath = $$DESTDIR/libFlawDetect*
DstPath = $$PWD/../Common/flaw/$$complied/
QMAKE_POST_LINK += $$QMAKE_COPY $$SrcPath $$DstPath

137、QMAKE_PRE_LINK

指定在将 TARGET 链接在一起之前要执行的命令。此变量通常为空，因此不会执行任何操作。注意：这个变量对 Xcode 项目没有影响。

35、LIBS

指定要链接到项目中的库列表。如果使用 Unix -l（库）和 -L（库路径）标志，qmake 会在 Windows 上正确处理库（即，将库的完整路径传递给链接器）。 该库必须存在以便 qmake 找到 -l lib 所在的目录。

如：

unix:LIBS += -L/usr/local/lib -lmath

win32:LIBS += c:/mylibs/math.lib

18、DEFINES

qmake 将此变量的值添加为编译器 C 预处理器宏。

17、CONFIG

指定项目配置和编译器选项。这些值由 qmake 内部识别并具有特殊含义。

以下 CONFIG 值控制编译器和链接器标志：

release：项目在发布模式下构建。如果还指定了 debug，则最后一个生效。

debug：项目在调试模式下构建。

debug_and_release：项目在调试和发布模式下构建。

debug_and_release_target：此选项是默认设置的。如果还设置了 debug_and_release，则 debug 和 release 构建最终位于单独的 debug 和 release 目录中。

build_all：如果指定了 debug_and_release，则默认以debug 和release 两种模式构建项目。

若不手动控制，自动跟着左下角的项目构建方式决定debug or release

precompile_header：支持在项目中使用预编译头。

precompile_header_c：（仅限 MSVC）支持使用 C 文件的预编译头。

warn_on：编译器应该输出尽可能多的警告。如果同时指定了warn_off，则最后一个生效。

warn_off：编译器应该尽可能少地输出警告。

exceptions：启用异常支持。默认设置。

exceptions_off：禁用异常支持。

ltcg：启用链接时间代码生成。 此选项默认关闭。

rtti：启用 RTTI 支持。默认情况下，使用编译器默认值。

rtti_off：禁用RTTI 支持。默认情况下，使用编译器默认值。

stl：启用STL 支持。默认情况下，使用编译器默认值。

stl_off：禁用STL 支持。默认情况下，使用编译器默认值。

thread：启用线程支持。当 CONFIG 包含 qt 时启用此功能，这是默认设置。

strict_c：禁用对 C 编译器扩展的支持。 默认情况下，处于启用状态。

c++11：启用 C++11 支持。如果编译器不支持 C++11 或无法选择 C++ 标准，则此选项无效。默认情况下，支持处于启用状态。

c++14：启用 C++14 支持。如果编译器不支持 C++14 或无法选择 C++ 标准，则此选项无效。默认情况下，支持处于启用状态。

c++17：启用 C++17 支持。如果编译器不支持 C++17 或无法选择 C++ 标准，则此选项无效。默认情况下，支持处于启用状态。

c++20：启用 C++20 支持。如果编译器不支持 C++20 或无法选择 C++ 标准，则此选项无效。默认情况下，支持处于禁用状态。

c++latest：启用对编译器支持的最新 C++ 语言标准的支持。 默认情况下，此选项处于禁用状态。

strict_c++：禁用对 C++ 编译器扩展的支持。默认情况下，处于启用状态。

depend_includepath：将 INCLUDEPATH 的值附加到 DEPENDPATH 。默认启用设置。

以下选项定义应用程序或库类型：

qt：目标是 Qt 应用程序或库，需要 Qt 库和头文件。Qt 库的正确包含和库路径将自动添加到项目中。这是默认定义的。

x11：目标是 X11 应用程序或库。正确的包含路径和库将自动添加到项目中。

windows：目标是一个 Win32 窗口应用程序。正确的包含路径、编译器标志和库将自动添加到项目中。

console：目标是一个 Win32 控制台应用程序。正确的包含路径、编译器标志和库将自动添加到项目中。

cmdline：目标是一个跨平台的命令行应用程序。在 Windows 上，这意味着 CONFIG += console。在 macOS 上，这意味着 CONFIG -= app_bundle。

shared、dll：目标是共享对象/DLL。 正确的包含路径、编译器标志和库将自动添加到项目中。dll也可以在所有平台上使用。将创建具有目标平台（.dll 或 .so）的适当后缀的共享库文件。

static、staticlib：目标是一个静态库（仅限 lib）。正确的编译器标志将自动添加到项目中。

plugin：目标是一个插件（仅限 lib）。 这也启用了 dll。

designer：目标是 Qt Designer 的插件。

这些选项仅定义 Windows 上的特定功能：

flat：当使用 vcapp 模板时，这会将所有源文件放入源组并将头文件放入头组，而不管它们驻留在哪个目录中。关闭此选项将根据目录对源/头组中的文件进行分组放置。这是默认开启的。

embed_manifest_dll：在作为库项目一部分创建的 DLL 中嵌入清单文件。

embed_manifest_exe：在作为应用程序项目的一部分创建的 EXE 中嵌入清单文件。

以下选项仅在 Linux/Unix 平台上生效：

largefile：包括对大文件的支持。

separate_debug_info：将库的调试信息放在单独的文件中。
```

qmake中使用的宏在文件 `C:\Qt\Qt5.14.2\5.14.2\msvc2017_64\mkspecs\features\spec_post.prf` 里定义具体实现方式，截取部分如：

![image.png](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/Ubuntu%E7%B3%BB%E7%BB%9F%E6%93%8D%E4%BD%9C/image4.png)

更多查看：

https://olimiya.github.io/posts/qmake%E4%B8%AD%E5%AE%9E%E7%8E%B0%E6%8B%B7%E8%B4%9D%E6%96%87%E4%BB%B6/

https://doc.qt.io/archives/qt-5.15/qmake-variable-reference.html

https://www.cnblogs.com/iriczhao/p/11274598.html

https://qthub.com/static/doc/qmlbook/cn/qt_and_c++/qmake.html

# CMake语法

cmake区分不同系统

```cpp
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(STATUS "Configuring on/for Linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    message(STATUS "Configuring on/for macOS")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(STATUS "Configuring on/for Windows")
elseif(CMAKE_SYSTEM_NAME STREQUAL "AIX")
    message(STATUS "Configuring on/for IBM AIX")
else()
    message(STATUS "Configuring on/for ${CMAKE_SYSTEM_NAME}")
endif()
```

todo

# 预定义宏

通过宏定义区分系统与编译器

```cpp
// 是否用VS编译
#if _MSC_VER >=1900 // VS2015或者以上
#ifdef _DEBUG
#pragma comment(lib,"opencv_world455d.lib")	
#else
#pragma comment(lib,"opencv_world455.lib")
#endif // _DEBUG
#endif

//系统宏
#ifdef __ANDROID__
	string port("/dev/ttyUSB1");
#elif __linux__
	string port("/dev/ttyUSB0");
#elif _WIN32
	string port("Com3");
#endif
 
//编译器宏
#ifdef _MSC_VER
	cout << "hello MSVC" << endl;
#elif __GNUC__
	cout << "hello gcc" << endl;
#elif __BORLANDC__
	cout << "hello Borland c++" << endl;
#endif

```

https://learn.microsoft.com/zh-cn/cpp/preprocessor/predefined-macros?view=msvc-170

# 安装企业微信等win应用

套壳安装

```jsx
// 将移植仓库添加到系统中
wget -O- https://deepin-wine.i-m.dev/setup.sh | sh

// 安装企业微信
sudo apt-get install com.qq.weixin.work.deepin

// 安装qq
sudo apt-get install com.qq.im.deepin
```

• 完整列表参见 [https://deepin-wine.i-m.dev](https://deepin-wine.i-m.dev/) 

ref:https://github.com/zq1997/deepin-wine

错误记录：

1. symbol lookup error
   
    **则作为dll调用时会报错：**App path:/home/lcq/Code/FlawDetect/x64/Debug/home/lcq/Code/FlawDetect/build-useFlawDetect-unknown-Debug/../x64/Debug/useFlawDetect: symbol lookup error: /home/lcq/Code/FlawDetect/x64/Debug/libFlawDetect.so: undefined symbol: _ZN3tbb6detail2r120isolate_within_arenaERNS0_2d113delegate_baseEl
    
    ```jsx
    ❯ c++filt _ZN3tbb6detail2r120isolate_within_arenaERNS0_2d113delegate_baseEl
    
    tbb::detail::r1::isolate_within_arena(tbb::detail::d1::delegate_base&, long)
    ```
    
    分析出是tbb庫，需要在qmake中加入
    `LIBS += -ltbb`
    
2. 

常用指令

筛选特定的包

`apt list --installed | grep "opencv"`