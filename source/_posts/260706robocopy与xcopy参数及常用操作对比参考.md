---
title: robocopy 与 xcopy 参数及常用操作对比参考
categories:
- 编程工具
tags:
- windows
- 命令行
- 文件复制
---

# robocopy 与 xcopy 参数及常用操作对比参考

> 适用平台：Windows（Win7 及以上推荐使用 robocopy；xcopy 兼容性更广，从 Win95 起即有，但功能弱）。
> 文档约定：所有示例路径均用 `\` 转义后书写，bat 中正常书写即可。

---

## 目录

1. [robocopy 完整参数速查表](#1-robocopy-完整参数速查表)
2. [xcopy 完整参数速查表](#2-xcopy-完整参数速查表)
3. [常用操作对照表（robocopy vs xcopy）](#3-常用操作对照表robocopy-vs-xcopy)
4. [返回码（ERRORLEVEL）说明](#4-返回码errorlevel说明)
5. [实战部署模板](#5-实战部署模板)

---

## 1. robocopy 完整参数速查表

### 1.1 源 / 目标 / 文件筛选

| 参数 | 含义 |
|------|------|
| `<source>` | 源目录路径（必填） |
| `<destination>` | 目标目录路径（必填） |
| `<file>` | 要操作的文件名或通配符（如 `*.dll`、`config.ini`），可选 |
| `/S` | 复制**非空**子目录 |
| `/E` | 复制子目录，**包括空的**（推荐替代 `/S`） |
| `/A` | 只复制带**存档属性**的文件，并保留存档属性 |
| `/M` | 只复制带**存档属性**的文件，复制完后**清除**存档属性（适合增量备份） |
| `/LEV:n` | 只复制源目录树的前 **n** 层 |
| `/MAXAGE:n` | 排除早于 n 天/日期的文件（如 `MAXAGE:7`） |
| `/MINAGE:n` | 排除晚于 n 天/日期的文件 |
| `/MAXSIZE:n` | 排除大于 n 字节的文件（如 `MAXSIZE:1048576`） |
| `/MINSIZE:n` | 排除小于 n 字节的文件 |
| `/XF file [file]...` | **排除**指定名字/通配符/路径的文件 |
| `/XD dir [dir]...` | **排除**指定目录 |
| `/XC` | 排除**已更改**的文件 |
| `/XN` | 排除**较新**的文件 |
| `/XO` | 排除**较旧**的文件（只覆盖较旧的目标，实现增量） |
| `/IS` | 包含**完全相同**的文件（默认会跳过） |
| `/IT` | 包含**被调整过的**文件（时间戳相同但属性不同） |

### 1.2 文件属性与安全

| 参数 | 含义 |
|------|------|
| `/A-:RASHCNET` | 去除指定属性（R=只读 A=存档 S=系统 H=隐藏 C=压缩 N=未索引 E=加密 T=临时） |
| `/A+:RASHCNET` | 添加指定属性 |
| `/COPY:copyflags` | 指定要复制的内容：`D=数据 A=属性 T=时间戳 S=安全=Ntfs ACL O=所有者 U=审核信息`，默认 `DAT` |
| `/COPYALL` | 等价于 `/COPY:DATSOU`（复制所有信息） |
| `/NOCOPY` | 不复制文件内容（仅操作文件列表） |
| `/SEC` | 等价于 `/COPY:DATS`（含安全 ACL） |
| `/DST` | 补偿 1 小时夏令时时差 |
| `/TIMFIX` | 修复目标文件的时间戳 |
| `/PURGE` | 删除目标中**不存在于源**的文件/目录（和 `/E` 合用） |
| `/MIR` | **镜像**：等价于 `/E /PURGE`，会删目标多余文件 |
| `/MOV` | 移动文件（复制后**删除源**） |
| `/MOVE` | 移动文件 + 目录（复制后**删除源**） |

### 1.3 重试与容错

| 参数 | 含义 |
|------|------|
| `/R:n` | 失败重试次数，**默认 1000000**（工业脚本必改 0~3） |
| `/W:n` | 重试间隔秒数，默认 30 |
| `/REG` | 将 `/R:n /W:n` 保存到注册表作为后续默认 |
| `/TBD` | 等待共享名定义（待定） |

### 1.4 日志

| 参数 | 含义 |
|------|------|
| `/L` | **仅列出**要执行的操作，不真正复制（dry-run） |
| `/X` | 报告所有**额外**的文件（不只限超出选择条件的） |
| `/V` | **详细**输出（含被跳过的文件） |
| `/TS` | 输出中**含源文件时间戳** |
| `/FP` | 输出中**含完整路径** |
| `/BYTES` | 以**字节**显示大小（默认 KB/MB） |
| `/NS` | 无文件大小 |
| `/NC` | 无文件类别（`*EXTRA`、`*Changed` 等标记） |
| `/NFL` | 无文件列表（不列文件名） |
| `/NDL` | 无目录列表（不列目录名） |
| `/NP` | 无进度百分比 |
| `/LOG:file` | 输出到日志文件（**覆盖**） |
| `/LOG+:file` | 输出到日志文件（**追加**） |
| `/UNILOG:file` | 以 **Unicode** 输出到日志 |
| `/UNILOG+:file` | 以 Unicode **追加**到日志 |
| `/TEE` | 同时输出到**屏幕和日志** |

### 1.5 性能

| 参数 | 含义 |
|------|------|
| `/J` | 使用**未缓冲 I/O**（适合大文件，企业版/Server 系统才有） |
| `/Z` | **可重启模式**（断点续传，网络拷贝用） |
| `/MT[:n]` | **多线程**，n 默认 8，最大 128；线程越多对磁盘压力越大 |
| `/IPG:n` | 包间间隙 ms（**限速**，n 为毫秒间隔） |
| `/COMPRESS` | 网络传输时启用 SMB 压缩（仅 Win11 24H2 / Server 2022+） |

### 1.6 输出显示（静默组合）

| 参数 | 含义 |
|------|------|
| `/NJH` | 无作业头（开头那段 源/目标/时间） |
| `/NJS` | 无作业摘要（结尾那段 统计） |

> `/NJH /NJS /NDL /NFL /NP /NC` 是工业部署最常见的"完全静默"组合。

### 1.7 调度（备份相关）

| 参数 | 含义 |
|------|------|
| `/RH:hhmm-hhmm` | 指定**运行时间窗口**（24h 制），如 `/RH:0930-1700` |
| `/PF` | 基于**运行频率**而非总时间（每小时检查一次） |
| `/MON:n` | 检测到 n 个变更后再次运行 |
| `/MOT:m` | m 分钟后若检测到变更则再次运行 |

---

## 2. xcopy 完整参数速查表

> xcopy 参数远少于 robocopy，能力较弱但兼容性最好。

| 参数 | 含义 |
|------|------|
| `/A` | 只复制带**存档属性**的文件，保留属性 |
| `/M` | 只复制带**存档属性**的文件，复制后清除属性 |
| `/D[:date]` | 只复制**指定日期或之后**修改的源文件（增量） |
| `/P` | 每个源文件前**提示确认**（脚本里通常不要用） |
| `/S` | 复制**非空**子目录 |
| `/E` | 复制**所有**子目录，包括空的 |
| `/V` | 校验每个新文件（写入后回读） |
| `/W` | 复制前等待按键（基本没人用） |
| `/C` | 出错也**继续**复制 |
| `/I` | **假定目标是目录**（避免脚本里被询问） |
| `/Q` | **静默**：复制时不显示文件名 |
| `/F` | 复制时显示**完整源和目标文件名** |
| `/L` | **仅列出**要复制的文件，不真正复制 |
| `/G` | 允许复制**加密文件**到不支持加密的目标 |
| `/H` | 复制**隐藏和系统文件** |
| `/R` | **覆盖只读文件**（默认会拒绝覆盖） |
| `/T` | 创建**目录结构**但不复制文件 |
| `/U` | 只复制**目标中已存在**的文件 |
| `/K` | 复制后**保留原始属性**（如只读） |
| `/N` | 用短文件名复制（兼容老 FAT） |
| `/O` | 复制**文件所有权和 ACL**（需管理员） |
| `/X` | 复制**文件审核设置**（需管理员） |
| `/Y` | **覆盖前不询问**（脚本里必加） |
| `/-Y` | 覆盖前**询问**（默认行为） |
| `/Z` | **可重启模式**（网络断点续传） |
| `/EXCLUDE:file[+file]` | 排除指定文件（每行一个排除模式，如 `obj\bin`） |
| `/?` | 显示帮助 |
| `/COMPRESS` | 网络传输时启用 SMB 压缩（同 robocopy） |

> ⚠️ xcopy 没有 `MAXAGE / MINAGE / 多线程 / 镜像` 这些能力，需要靠 robocopy 或 PowerShell。

---

## 3. 常用操作对照表（robocopy vs xcopy）

> 同一种操作，先列 **robocopy 写法**，再列 **xcopy 写法**，方便对照。

### 3.1 拷贝单个文件

**robocopy**

```bat
robocopy "G:\Src" "G:\Dst" "config.ini"
```

> 必须给一个目录作源，再指定文件名。**不能直接两个文件路径对拷**。

**xcopy**

```bat
xcopy "G:\Src\config.ini" "G:\Dst\config.ini" /Y
```

> xcopy 支持**直接两个文件路径**对拷。

---

### 3.2 拷贝整个文件夹（含子目录）

**robocopy**

```bat
robocopy "G:\Src\Models" "E:\Backup\Models" /E
```

> `/E` 包含子目录与空目录。

**xcopy**

```bat
xcopy "G:\Src\Models" "E:\Backup\Models" /E /I /Y
```

> `/E` 含空子目录；`/I` 当目标不存在时假定为目录，避免被询问。

---

### 3.3 仅复制目录结构（不要文件）

**robocopy**

```bat
robocopy "G:\Src" "G:\Dst" /E /NOCOPY
```

**xcopy**

```bat
xcopy "G:\Src" "G:\Dst" /E /T /I /Y
```

---

### 3.4 仅复制比目标更新的文件（增量同步）

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /XO
```

> `/XO` 排除较旧文件，源不更新则不复制。**最常用的同步写法**。

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /D:%date:~0,4%-%date:~5,2%-%date:~8,2%
```

> xcopy 的 `/D` 需要指定日期，无法直接"比目标新"，常用 `/D:0` 表示仅复制"昨天及以后"。`%date%` 展开后传给 `/D` 是常见做法。
>
> 工业里更稳的写法是用 PowerShell：
>
> ```powershell
> robocopy "G:\Src" "E:\Dst" /E /XO
> ```

---

### 3.5 强制覆盖不询问

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /IS /IT
```

> 默认 robocopy 就**不会询问**是否覆盖（不像 xcopy）。
> `/IS /IT` 强制覆盖"相同"和"调整过"的文件（连大小/时间戳都不看）。

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /R
```

> `/Y` 不询问覆盖；`/R` 同时允许覆盖只读文件。

---

### 3.6 静默执行（不显示任何信息）

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /NJH /NJS /NDL /NFL /NP /NC >nul 2>&1
```

> 屏幕完全静默；`>nul 2>&1` 把 stdout / stderr 都丢掉。
> 调试时去掉 `/NFL /NP` 就能看到文件名与进度。

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /Q >nul 2>&1
```

> `/Q` 静默；`>nul 2>&1` 丢弃剩余提示。`/Q` 仍可能打印结尾摘要。

---

### 3.7 只输出到日志文件（不显示屏幕）

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /R:0 /W:1 /LOG+:C:\Logs\sync.log /TS /FP
```

> `/LOG+` 追加；`/TS` 日志带时间戳；`/FP` 日志带完整路径。
> 想屏幕 + 日志同时输出，加 `/TEE`。

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y > C:\Logs\sync.log 2>&1
```

> xcopy 本身无日志选项，只能用 shell 重定向。

---

### 3.8 失败不重试 / 失败重试 N 次

**robocopy**

```bat
:: 不重试
robocopy "G:\Src" "E:\Dst" /E /R:0 /W:1

:: 重试 3 次，每次间隔 5 秒
robocopy "G:\Src" "E:\Dst" /E /R:3 /W:5
```

> ⚠️ **robocopy 默认 `/R:1000000 / W:30`**，**工业脚本必改**。

**xcopy**

```bat
:: xcopy 失败时直接进下一个文件，不重试
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /C

:: xcopy 没有内置重试，失败只显示 F:\xxx
```

> xcopy 没有重试参数，只能靠 `/C`（出错继续）。需要重试逻辑请用 `for` + 自定义 bat，或直接上 robocopy。

---

### 3.9 镜像同步（含删除目标多余文件）

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /MIR /R:0 /W:1
```

> `/MIR` = `/E + /PURGE`，**会把目标里源没有的文件/目录删掉**。
> ⚠️ 慎用，先用 `/L` dry-run 一次确认。

**xcopy**

```bat
:: xcopy 没有镜像，需要两步
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y
:: 删多余文件... xcopy 没这个能力，得另写脚本
```

> 工业镜像同步请直接用 robocopy。

---

### 3.10 多线程拷贝（加速大目录）

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /MT:16 /R:0 /W:1
```

> `/MT:n` 启用 n 线程，默认 8，最大 128。
> ⚠️ 线程多 ≠ 一定快：磁盘 SSD/HDD、文件大小、并发读写都会影响收益。机械盘建议 2~4 线程。

**xcopy**

```bat
REM xcopy 不支持多线程
```

> 这是 xcopy 时代落幕的根本原因之一。

---

### 3.11 限制带宽（防压垮网络）

**robocopy**

```bat
robocopy "\\fileserver\share" "E:\Dst" /E /IPG:10
```

> `/IPG:10` 表示包间间隙 10ms，**越大越慢**。1ms ≈ 80% 带宽；5ms ≈ 30%。

**xcopy**

```bat
REM xcopy 没有带宽限制
```

---

### 3.12 跳过特定扩展名 / 文件

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /XF *.tmp *.log *.bak
```

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /EXCLUDE:exclude.txt
```

> `exclude.txt` 每行一个排除模式，例如：
>
> ```
> .tmp
> .log
> .bak
> ```

---

### 3.13 跳过特定目录

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /XD ".git" "node_modules" "bin" "obj"
```

**xcopy**

```bat
REM xcopy 不支持，需要在 exclude.txt 里写路径模式
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /EXCLUDE:exclude.txt
```

> exclude.txt 里写：
>
> ```
> \.git\
> \node_modules\
> \bin\
> \obj\
> ```

---

### 3.14 复制隐藏文件 / 系统文件

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /A+:H
```

> 默认 robocopy **不复制隐藏/系统文件**，需要 `/A+:H` 显式加。

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /H
```

> `/H` 复制隐藏和系统文件。

---

### 3.15 复制并保留时间戳 / ACL

**robocopy**

```bat
:: 仅时间戳与属性（默认）
robocopy "G:\Src" "E:\Dst" /E /COPY:DAT

:: 含 NTFS ACL
robocopy "G:\Src" "E:\Dst" /E /COPY:DATS /SEC

:: 含所有者与审核信息（需管理员）
robocopy "G:\Src" "E:\Dst" /E /COPYALL
```

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /O /X
```

> `/O` 含所有权 + ACL，`/X` 含审核信息；都需管理员权限。
> xcopy 默认保留时间戳，但 ACL 要靠 `/O`。

---

### 3.16 拷贝后删除源（移动文件）

**robocopy**

```bat
:: 移动文件（保留目录结构）
robocopy "G:\Src" "E:\Dst" /E /MOV /R:0 /W:1

:: 移动文件 + 空目录
robocopy "G:\Src" "E:\Dst" /E /MOVE /R:0 /W:1
```

**xcopy**

```bat
REM xcopy 不支持移动；删源要自己写 del / rd
```

> 移动文件场景请用 robocopy 或 PowerShell `Move-Item`。

---

### 3.17 Dry-run（仅列出，不真复制）

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /L /V
```

> `/L` 仅列出；常配合 `/V` 看哪些会被跳过。

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /L
```

---

### 3.18 大文件 + 断点续传

**robocopy**

```bat
robocopy "\\share\big.iso" "E:\Dst" /Z /IPG:5
```

> `/Z` 可重启模式，**网络中断可续传**；`/IPG:5` 限速保护共享。

**xcopy**

```bat
xcopy "\\share\big.iso" "E:\Dst\" /Z /Y
```

---

### 3.19 仅复制特定类型（按扩展名筛选）

**robocopy**

```bat
:: 只复制 .dll 和 .ini
robocopy "G:\Src" "E:\Dst" *.dll *.ini /S

:: 只复制 .log
robocopy "G:\Src" "E:\Dst" *.log /S /MAXAGE:7
```

**xcopy**

```bat
:: 只复制 dll
xcopy "G:\Src\*.dll" "E:\Dst\" /S /I /Y
```

> xcopy 只能用通配符在源路径上写，robocopy 可以 `<files>` 位置写多个通配符。

---

### 3.20 处理被占用文件 / 出错继续

**robocopy**

```bat
robocopy "G:\Src" "E:\Dst" /E /R:2 /W:3
```

> 默认失败重试 100 万次会卡死。改为 2 次 / 间隔 3 秒，**最多卡 6 秒**。

**xcopy**

```bat
xcopy "G:\Src\*.*" "E:\Dst\" /E /I /Y /C
```

> `/C` 出错继续，遇到占用文件会**跳过并打印 F:\xxx**，不中断。

---

## 4. 返回码（ERRORLEVEL）说明

### 4.1 robocopy 返回码

| ERRORLEVEL | 含义 | 是否当失败 |
|-----------|------|----------|
| 0  | 无文件被复制（源与目标一致） | 否 |
| 1  | 一个或多个文件被成功复制 | 否 |
| 2  | 检测到一些额外文件（目标中源没有的） | 看场景 |
| 3  | 1 + 2 都发生 | 看场景 |
| 4~7 | 部分错误（权限、共享冲突等） | **看场景** |
| ≥8  | 严重失败 | **是** |

**推荐判断**：

```bat
if %ERRORLEVEL% GEQ 8 (
    echo [ERROR] robocopy 失败
    exit /b 1
)
```

### 4.2 xcopy 返回码

| ERRORLEVEL | 含义 |
|-----------|------|
| 0 | 成功复制，无错误 |
| 1 | 没找到要复制的文件 |
| 2 | 用户按 Ctrl+C 终止 |
| 3 | 至少一次错误（脚本里基本等同失败） |
| 4 | 写入目标时磁盘空间不足 |
| 5 | 磁盘写入错误 |

**判断**：

```bat
if %ERRORLEVEL% NEQ 0 exit /b 1
```

---

## 5. 实战部署模板

### 5.1 robocopy 生产部署模板（推荐）

```bat
@echo off
setlocal

set SRC=\\fileserver\config\%COMPUTERNAME%
set DST=C:\App\config
set LOG=C:\Logs\sync_%date:~0,4%%date:~5,2%%date:~8,2%.log

:: /E        含子目录 + 空目录
:: /XO       增量（只覆盖较旧目标）
:: /R:0 /W:1 失败不重试，立即跳过
:: /MT:8     8 线程
:: /IPG:5    限速（包间 5ms，保护共享）
:: /NFL /NP  屏幕静默（不加可看进度）
:: /LOG+     写日志，追加
:: /TS /FP   日志带时间戳 + 完整路径
robocopy "%SRC%" "%DST%" ^
    /E /XO /R:0 /W:1 /MT:8 /IPG:5 ^
    /NJH /NJS /NFL /NP /NC /NDL ^
    /LOG+:"%LOG%" /TS /FP /BYTES

if %ERRORLEVEL% GEQ 8 (
    echo [ERROR] config 同步失败 code=%ERRORLEVEL% >> "%LOG%"
    exit /b 1
)

exit /b 0
```

### 5.2 xcopy 简化模板（兼容性优先）

```bat
@echo off
setlocal

set SRC=C:\Src\Models
set DST=E:\Backup\Models

xcopy "%SRC%\*.*" "%DST%\" /E /I /Y /H /R /C /Q >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] xcopy 失败 code=%ERRORLEVEL%
    exit /b 1
)

exit /b 0
```

### 5.3 选型建议

| 场景 | 推荐 |
|------|------|
| 老旧系统（Win XP）、运维脚本最低兼容 | xcopy |
| Windows 7 及以上、生产部署、定期同步 | **robocopy** |
| 镜像、增量、限速、多线程 | **robocopy** |
| 移动文件、带权限复制 | **robocopy** |
| 简单一次性复制两三个文件 | xcopy |

---

> 文档版本：v1.0  
> 适用对象：工业视觉工程师 / 运维工程师  
> 参考资料：Microsoft Docs（robocopy / xcopy）
