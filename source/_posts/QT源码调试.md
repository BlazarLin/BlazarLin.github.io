---
title: Qt 源码调试与 PDB 配置指南
categories: 
- QT编程
tags: 
- c++
- QT
- 调试
- PDB
---

# Qt 源码调试与 PDB 配置指南

> 适用环境：**Windows + Visual Studio 2019 + Qt 5.14.2 + MSVC 2017 64-bit**（`msvc2017_64`）。
> 目标：在 VS 中单步进入 Qt 源码、查看 Qt 内部变量，并正确对应调用栈行号。

## 1. Sources、DLL 与 PDB 的关系

| 名称 | 作用 | 能否单独用于 F11 进入 Qt |
|------|------|--------------------------|
| Qt 预编译库（`Qt5Core.dll` 等） | 运行和链接使用的二进制 | 否 |
| Qt Sources（`5.14.2\Src`） | 与调用栈对应的源代码 | 否，只能手动打开源码对照 |
| Debug Information / PDB | DLL 对应的符号与源码映射信息 | 是，但还需配置源码路径 |

仅安装 `C:\Qt\Qt5.14.2\5.14.2\Src` 不够。要从 DLL 调用栈进入 Qt 源码，必须同时准备与当前 kit 严格匹配的 PDB。

以下三项必须一致：

- Qt 小版本，例如 `5.14.2`，不能混用 `5.14.1` 的 PDB；
- 编译器套件，例如 `MSVC 2017 64-bit`；
- 构建类型，Release 程序使用 Release Qt DLL 及其 PDB，Debug 程序使用 `Qt5Cored.dll` 及对应符号。

## 2. 确认程序实际加载的 Qt

在 VS 中打开 **调试 → 窗口 → 模块**，找到 `Qt5Core.dll` 并记录完整路径，例如：

```text
C:\Qt\Qt5.14.2\5.14.2\msvc2017_64\bin\Qt5Core.dll
```

后续下载和配置的 PDB 必须对应这个 kit。系统环境变量中不要同时混入多个 Qt 版本路径，否则程序可能加载另一套 DLL，导致符号无法匹配。

## 3. 获取 Qt PDB

### 3.1 使用 Qt 维护工具

运行 Qt 安装目录下的 `MaintenanceTool.exe`，打开 **设置 → 资料档案库**，添加与 Qt 版本对应的在线仓库：

![Qt 维护工具资料档案库](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_maintain.png)

```text
https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5142/
https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/tools_mingw/
https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5142_src_doc_examples/
```

国内网络也可以使用清华镜像：

```text
https://mirrors.tuna.tsinghua.edu.cn/qt/online/qtsdkrepository/windows_x86/desktop/qt5_5142/
```

在 **添加或移除组件** 中查找与 `MSVC 2017 64-bit` 对应的 **Qt Debug Information Files** 或类似名称，勾选后安装。

![Qt Debug Information Files](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_debuginfo.png)

若组件树中只有 Sources、没有 Debug Information，直接使用下一种方式，不必反复调整维护工具仓库。

### 3.2 手动下载符号包

Qt 5.14.2 的 MSVC 2017 64-bit 符号包位于：

<https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5142/qt.qt5.5142.debug_info.win64_msvc2017_64/>

![Qt 符号包下载目录](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_basefile.png)

操作步骤：

1. 下载文件名包含 `debug-symbols` 的 `.7z` 包；
2. 至少下载 `qtbase`，其中包含 `Qt5Core`、`Qt5Gui`、`Qt5Widgets` 等核心模块的 PDB；
3. 使用 QML、WebEngine、Charts 等模块时，再按需下载对应包；
4. 用 7-Zip 解压并合并到当前 kit，不要新建另一套 Qt：

   ```text
   C:\Qt\Qt5.14.2\5.14.2\msvc2017_64\
   ```

5. 确认 `bin`、`lib` 等目录中出现与 DLL 对应的 `.pdb`，例如 `Qt5Core.pdb`。

Qt 的 archive 页面主要提供安装器和源码包。单独的符号包位于 online repository 的 `debug_info` 目录。

### 3.3 从源码编译 Qt

维护工具和在线仓库均不满足要求时，可以使用相同 MSVC 工具链自行编译 Qt：

```cmd
cd C:\Qt\Qt5.14.2\5.14.2\Src
configure -prefix C:\Qt\Qt5.14.2\5.14.2\msvc2017_64 -release -force-debug-info -nomake examples -nomake tests
nmake
```

编译完成后，工程必须链接并运行这一套 Qt，否则新生成的 PDB 仍然无法匹配实际 DLL。

## 4. Visual Studio 2019 配置

### 4.1 添加符号路径

进入 **调试 → 选项 → 调试 → 符号**，添加当前 kit 的 `bin` 和 `lib`：

```text
C:\Qt\Qt5.14.2\5.14.2\msvc2017_64\bin
C:\Qt\Qt5.14.2\5.14.2\msvc2017_64\lib
```

![Visual Studio 符号路径](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_srcpath.png)

Microsoft 符号服务器只能提供系统 DLL 符号，不能代替 Qt PDB。

### 4.2 添加源码路径

在 VS 的源文件路径中添加：

```text
C:\Qt\Qt5.14.2\5.14.2\Src
```

![Visual Studio Qt 源码路径](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_pdb.png)

PDB 中记录的源码位置会在此目录下解析，例如 `qtbase\src\corelib\json\qjsonobject.cpp`。

### 4.3 关闭“仅我的代码”

进入 **调试 → 选项 → 调试 → 常规**，取消勾选 **启用“仅我的代码”**，否则 VS 通常不会单步进入 Qt 内部实现。

### 4.4 验证符号加载

1. F5 启动程序并停在任意断点；
2. 打开 **调试 → 窗口 → 模块**；
3. 找到 `Qt5Core.dll`，确认符号列显示 **已加载符号**，并检查 PDB 路径；
4. 在 Qt 调用栈帧上按 F11，应能进入 `Src` 下对应的 `.cpp`。

![断点进入 Qt 源码](https://blazarnoteimages.oss-cn-beijing.aliyuncs.com/qt_showfunc.png)

## 5. 自有 DLL 的调试信息

Qt PDB 只负责 Qt 库本身。调试自有 EXE/DLL 时，Debug 和 Release 均应保留编译调试信息与链接器 PDB：

- MSVC 编译调试信息使用 `/Zi`；
- 链接器启用 `/DEBUG` 并生成 `.pdb`；
- Release 仍保持优化，用 PDB 对应优化后的调用栈；
- VS 符号路径加入自有 EXE/DLL 的实际输出目录。

## 6. 常见问题

### 6.1 维护工具中找不到 Debug Information Files

这是常见情况。直接进入对应版本和编译器套件的 `debug_info` 在线仓库，手动下载 `debug-symbols.7z`。

### 6.2 已加载符号，但 F11 仍进不去 Qt

- 检查是否关闭“仅我的代码”；
- 检查 `Src` 路径是否已添加；
- 检查当前栈帧是否确实位于 Qt DLL，而不是应用程序代码；
- 在模块窗口核对实际加载的 DLL 与 PDB 路径。

### 6.3 PDB 与 DLL 不匹配

常见表现是符号拒绝加载、行号错乱或变量无法查看。重新核对 Qt 小版本、MSVC 套件、位数以及 Release/Debug 类型。

### 6.4 Release 程序能否调试 Qt

可以。应使用 Release Qt DLL 对应的 `debug_info` 符号包，而不是 Debug 版本的 `Qt5Cored.dll`。

### 6.5 是否需要安装所有模块的 PDB

通常不需要。`qtbase` 足够覆盖 Core、Gui、Widgets；其他模块按实际调用栈下载，可以显著减少磁盘占用。

## 7. 快速检查清单

```text
□ 已在模块窗口确认 Qt5Core.dll 的实际路径
□ PDB 与 Qt 小版本、MSVC 套件、位数和构建类型一致
□ PDB 已解压到当前 kit 的 bin/lib
□ VS 符号路径已添加 bin 和 lib
□ VS 源码路径已添加 5.14.2\Src
□ 已关闭“仅我的代码”
□ 模块窗口显示 Qt5Core.dll 已加载符号
□ F11 可以进入 qtbase 下的 .cpp 文件
```

## 8. 参考链接

- [Qt 5.14.2 归档](https://download.qt.io/archive/qt/5.14/5.14.2/)
- [Qt 5.14.2 在线仓库](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5142/)
- [MSVC 2017 64-bit 符号包目录](https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt5_5142/qt.qt5.5142.debug_info.win64_msvc2017_64/)
- [VS2017 调试 Qt 源码](https://ifmet.cn/posts/134fdafb/)
- [Qt 5.12 调试信息安装](https://blog.simbot.net/2019/07/28/qt-debug-symbols/)
