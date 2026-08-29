---
title: Pi Agent Windows 使用指南（含火山引擎模型配置）
categories:
- Agent
tags:
- Pi Agent
- windows
- AI编程工具
---

# Pi Agent Windows 使用指南（含火山引擎模型配置）

> 本指南面向 Windows 用户，从零开始安装 Pi Agent，并完成火山引擎（方舟 Ark）编程智能体模型的配置。
> Pi 官方文档：<https://pi.dev> ｜ npm 包：`@earendil-works/pi-coding-agent`

---

## 目录

- [一、Pi Agent 是什么](#一pi-agent-是什么)
- [二、Windows 环境准备](#二windows-环境准备)
- [三、安装 Pi](#三安装-pi)
- [四、配置目录结构](#四配置目录结构)
- [五、配置火山引擎模型（核心）](#五配置火山引擎模型核心)
  - [5.1 准备工作](#51-准备工作)
  - [5.2 模型对照表](#52-模型对照表)
  - [5.3 让另一个 Pi Agent 自动配置](#53-让另一个-pi-agent-自动配置)
- [六、日常使用](#六日常使用)
- [七、开启思考模式（可选）](#七开启思考模式可选)
- [八、常见问题排查](#八常见问题排查)

---

## 一、Pi Agent 是什么

Pi 是一个极简的终端编程智能体框架（terminal coding agent harness）。它默认提供 `read`、`write`、`edit`、`bash` 四个工具，让大模型在你的本地完成读写文件、执行命令等开发任务。

它的特点是：

- **极简内核 + 强扩展**：通过 Skills、Extensions、Prompt Templates、Themes 自定义工作流。
- **多 Provider 支持**：内置 Anthropic、OpenAI、DeepSeek、Google、Kimi、MiniMax 等几十家；不内置的（如火山引擎）可用 `models.json` 自定义接入。
- **多模式运行**：交互模式（默认）、打印模式 `-p`、JSON 模式、RPC 模式、SDK 嵌入。
- **会话管理**：自动保存、分支、压缩、恢复。

---

## 二、Windows 环境准备

Pi 在 Windows 上需要一个 **bash shell** 来运行 `bash` 工具。推荐安装 **Git for Windows**（自带 Git Bash）。

### 2.1 安装 Node.js（必需，>= 18）

1. 前往 <https://nodejs.org> 下载 LTS 版本（建议 20+）。
2. 安装时勾选 "Add to PATH"。
3. 验证：

   ```powershell
   node -v
   npm -v
   ```

### 2.2 安装 Git for Windows（提供 bash）

1. 前往 <https://git-scm.com/download/win> 下载并安装。
2. Pi 会自动检测 `C:\Program Files\Git\bin\bash.exe`。
3. 验证 bash 可用：

   ```powershell
   bash --version
   ```

> 若你用 Cygwin / MSYS2 / WSL，也可在 `settings.json` 里指定：
>
> ```json
> { "shellPath": "C:\\cygwin64\\bin\\bash.exe" }
> ```

### 2.3 推荐终端

建议使用 **Windows Terminal**（Win11 默认自带，Win10 可从 Microsoft Store 安装），对颜色、图片、快捷键支持最好。

---

## 三、安装 Pi

打开 PowerShell 或 Windows Terminal，执行全局安装：

```powershell
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

> `--ignore-scripts` 关闭依赖的安装期生命周期脚本，Pi 正常使用不需要它们。

安装完成后验证：

```powershell
pi --version
pi --help
```

能看到版本号和帮助说明，即安装成功。

升级 Pi：

```powershell
pi update --self
```

---

## 四、配置目录结构

Pi 的配置默认存放在用户主目录下的 `~/.pi/agent/`，在 Windows 上即：

```
C:\Users\<你的用户名>\.pi\agent\
```

核心文件：

| 文件 | 作用 |
|------|------|
| `settings.json` | 全局设置（默认模型、主题、思考等级、重试、压缩等） |
| `models.json` | **自定义 Provider 与模型**（火山引擎就在这里配） |
| `auth.json` | 存放 API Key / OAuth 凭据（由 `/login` 写入，也可手写） |
| `keybindings.json` | 自定义快捷键 |
| `sessions/` | 会话 JSONL 文件目录 |
| `extensions/`、`skills/`、`prompts/`、`themes/` | 扩展、技能、提示模板、主题 |

项目级配置可放在项目根目录的 `.pi/settings.json`，会覆盖全局设置。

---

## 五、配置火山引擎模型（核心）

火山引擎「方舟 Agent Plan」不是 Pi 的内置 Provider，通过 `~/.pi/agent/models.json` 自定义接入。支持两种兼容协议，**任选其一**：

| 协议 | Base URL | Pi `api` 值 |
|------|----------|------------|
| OpenAI 兼容（推荐） | `https://ark.cn-beijing.volces.com/api/coding/v3` | `openai-completions` |
| Anthropic 兼容 | `https://ark.cn-beijing.volces.com/api/coding` | `anthropic-messages` |

### 5.1 准备工作

1. 在 [火山引擎方舟控制台](https://console.volcengine.com/ark) 开通 Agent Plan，创建 API Key（形如 `xxxx-xxxx-xxxx`）。
2. 设置环境变量（避免硬编码进配置文件）：
   ```powershell
   setx ARK_API_KEY "你的火山引擎API Key"
   ```
   > `setx` 后需**新开终端**生效。

### 5.2 模型对照表

> 参数来自「方舟 Agent Plan」官方文档（doc 2366394），并已与本机 pi 实际配置核对：上下文窗口按 1k=1024 换算；最大输出 token 以 pi models.json 实际值为准（doubao-seed-2.0-lite / minimax-m2.7 / minimax-m3 / glm-5.2 为 128000）。

| Model Name | 说明 | 上下文窗口 | 最大输出 |
|------------|------|-----------|---------|
| `doubao-seed-2.1-turbo` | 豆包 Seed 2.1 Turbo（进阶） | 262144 (256k) | 262144 (256k) |
| `doubao-seed-2.0-lite` | 豆包 Seed 2.0 Lite（标准） | 262144 (256k) | 128000 (128k) |
| `minimax-m2.7` | MiniMax M2.7（进阶） | 204800 (200k) | 128000 (128k) |
| `minimax-m3` | MiniMax M3（进阶） | 524288 (512k) | 128000 (128k) |
| `glm-5.2`（别名 `glm-latest`） | 智谱 GLM 5.2（进阶） | 1048576 (1024k) | 128000 (128k) |
| `deepseek-v4-flash` | DeepSeek V4 Flash（标准） | 1048576 (1024k) | 393216 (384k) |
| `deepseek-v4-pro` | DeepSeek V4 Pro（进阶） | 1048576 (1024k) | 393216 (384k) |
| `kimi-k2.6` | Kimi K2.6（进阶） | 262144 (256k) | 32768 (32k) |
| `kimi-k2.7-code` | Kimi K2.7 Code（进阶） | 262144 (256k) | 32768 (32k) |

> ⚠️ **合规红线**：Agent Plan 的 Key **仅限在 AI 工具（Pi/Claude Code/Codex 等）中使用**，裸 API 调用会被判滥用、封号。
> ℹ️ `glm-5.2`、`deepseek-v4-*`、`kimi-k3` 支持 1M 上下文，但需在工具中按官方指引开启。官方还有 `doubao-seed-2.0-mini`、`doubao-seed-evolving`、`kimi-k3` 等模型，需要可自行加入。

### 5.3 让另一个 Pi Agent 自动配置

把下面这段提示词发给另一台机器上的 Pi Agent，它就能自动完成 `models.json` + `settings.json` 的写入与验证：

```
你是 Pi Agent 配置助手。请按以下步骤为本机配置火山引擎方舟 Agent Plan 模型：

1. 读取环境变量 ARK_API_KEY；若未设置，提示用户先执行 `setx ARK_API_KEY "你的Key"` 并重开终端。
2. 写入 ~/.pi/agent/models.json（Windows 下即 C:\Users\<用户名>\.pi\agent\models.json），provider key 用 volcano，baseUrl 为 https://ark.cn-beijing.volces.com/api/coding/v3，api 为 openai-completions，apiKey 用 "$ARK_API_KEY" 引用环境变量。
3. models 数组按下表填入。每个模型对象完整结构如下（以 reasoning=true 模型为例）：
   {
     "id": "<id>",
     "name": "<人类可读名>",
     "reasoning": true,
     "input": ["text"],
     "contextWindow": <ctx>,
     "maxTokens": <max>,
     "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
     "compat": { "supportsDeveloperRole": false, "thinkingFormat": "deepseek" },
     "thinkingLevelMap": { "minimal": null, "low": null, "medium": null, "high": "high", "max": "max" }
   }
   各模型的 id / contextWindow / maxTokens / reasoning 按下表填入（name 自取可读名，如 Doubao Seed 2.1 Turbo）：
   doubao-seed-2.1-turbo  262144  / 262144  / true
   doubao-seed-2.0-lite   262144  / 128000  / false
   minimax-m2.7           204800  / 128000  / true
   minimax-m3             524288  / 128000  / true
   glm-5.2                1048576 / 128000  / true
   deepseek-v4-flash      1048576 / 393216  / true
   deepseek-v4-pro        1048576 / 393216  / true
   kimi-k2.6              262144  / 32768   / true
   kimi-k2.7-code         262144  / 32768   / true
   注意：doubao-seed-2.0-lite 为 reasoning=false，去掉 compat.thinkingFormat 与 thinkingLevelMap（compat 仅保留 supportsDeveloperRole:false）；其余 8 个模型保持 reasoning=true 并含上述完整字段。thinkingLevelMap 中 medium 映射为 null（不发送思考参数），仅 high→high、max→max 会启用思考。
4. 写入 ~/.pi/agent/settings.json，设 defaultProvider=volcano、defaultModel=doubao-seed-2.1-turbo、defaultThinkingLevel=medium。
5. 执行 `pi --list-models volcano` 验证模型已加载；再执行 `pi --provider volcano --model doubao-seed-2.1-turbo -p "用一句话介绍你自己"` 验证连通。
6. 若第 5 步报未授权，检查 ARK_API_KEY 是否生效（需新开终端）；若报模型不存在，核对 id 拼写。
```

> 提示词给出完整模型对象模板 + 一张精确取值表（id/上下文/输出/reasoning），公共字段（input/cost/compat/thinkingLevelMap）只声明一次，Agent 据此即可生成与本机 pi 一致的 models.json。配置文件每次打开 `/model` 时自动重载，改完无需重启 Pi。

---

## 六、日常使用

### 6.1 启动方式

```powershell
pi                      # 交互模式（默认）
pi "列出 src 下的所有 ts 文件"   # 带初始提示启动
pi -c                   # 继续最近一次会话
pi -r                   # 浏览并选择历史会话
pi -p "总结这个仓库"     # 非交互，打印结果后退出
```

### 6.2 常用斜杠命令

| 命令 | 作用 |
|------|------|
| `/model` | 切换模型（火山引擎的模型会出现在列表中） |
| `/login` `/logout` | 管理凭据 |
| `/settings` | 调整思考等级、主题、传输方式等 |
| `/new` | 新建会话 |
| `/resume` | 恢复历史会话 |
| `/tree` | 会话树导航/分支 |
| `/compact` | 手动压缩上下文 |
| `/session` | 查看当前会话信息（ID、token、花费） |
| `/hotkeys` | 查看所有快捷键 |
| `/quit` | 退出 |

### 6.3 常用快捷键

| 快捷键 | 作用 |
|--------|------|
| `Ctrl+L` | 打开模型选择器 |
| `Ctrl+P` / `Shift+Ctrl+P` | 在限定模型间循环切换 |
| `Shift+Tab` | 切换思考等级 |
| `Ctrl+C` | 清空编辑器（连按两次退出） |
| `Esc` | 取消/中止（连按两次打开 `/tree`） |
| `Shift+Enter` | 换行（Windows Terminal 下用 `Ctrl+Enter`） |
| `Ctrl+G` | 打开外部编辑器（默认 Notepad） |
| `Ctrl+O` | 折叠/展开工具输出 |
| `Ctrl+X` | 复制上一条助手消息 |

### 6.4 编辑器技巧

- 输入 `@` 模糊搜索并引用项目文件。
- `Tab` 补全路径。
- `!命令` 执行 bash 命令并把输出发给模型；`!!命令` 执行但不发送。
- `Ctrl+V`（Windows 上用 `Alt+V`）粘贴文本或图片，也可把图片拖到终端。

### 6.5 上下文文件

在项目根目录放 `AGENTS.md`（或 `CLAUDE.md`），Pi 启动时会自动加载，用于写项目约定、常用命令等。也可放全局的 `~/.pi/agent/AGENTS.md`。

---

## 七、开启思考模式（可选）

火山引擎的 DeepSeek V4 Pro、豆包 Seed 系列等支持「深度思考」。若要让 Pi 给这些模型发送思考参数，在 `models.json` 对应模型上加 `"reasoning": true`：

```json
{
  "id": "deepseek-v4-pro",
  "name": "DeepSeek V4 Pro",
  "reasoning": true,
  "input": ["text"],
  "contextWindow": 1048576,
  "maxTokens": 393216
}
```

然后用 `Shift+Tab` 切换思考等级（off / minimal / low / medium / high）。

> **注意**：思考参数的具体格式取决于火山引擎接口的实现。若开启后出现参数不被接受的报错，可：
> - 保持 `reasoning: true`，并在模型上添加 `compat` 字段微调（OpenAI 协议下常用 `thinkingFormat`，例如 `"deepseek"`、`"qwen"` 等，详见 Pi 文档 [models.md](https://pi.dev/docs/models) 的 *OpenAI Compatibility* 一节）；
> - 或暂时去掉 `reasoning`，先保证基本对话/工具调用可用。
>
> 具体兼容性以火山引擎编程智能体官方文档为准。

---

## 八、常见问题排查

**Q1：`pi --list-models volcano` 列不出模型 / 提示未授权？**
- 确认环境变量 `ARK_API_KEY` 已设置：`echo $env:ARK_API_KEY`（PowerShell）。
- 用 `setx` 设置后必须**新开终端**。
- 也可临时用 `--api-key` 覆盖测试：`pi --api-key "你的key" --provider volcano --model doubao-seed-2.1-turbo -p "hi"`。

**Q2：请求报 401 / 鉴权失败？**
- API Key 是否在火山引擎控制台已创建且未失效。
- 是否已开通对应模型（开通管理页面）。
- `models.json` 里 `apiKey` 是否写成 `"$ARK_API_KEY"`（带 `$` 才会读环境变量；不带 `$` 会被当字面量）。

**Q3：Anthropic 兼容方案报 404 / 路径不对？**
- Pi 的 `anthropic-messages` 会在 `baseUrl` 后拼接 `/v1/messages`。若火山引擎该端点路径不同，可尝试把 `baseUrl` 调整为带或不带末尾斜杠的形式，或改用 OpenAI 兼容方案。

**Q4：`bash` 工具无法执行 / 提示找不到 bash？**
- 安装 Git for Windows，或 在 `settings.json` 设置 `"shellPath": "C:\\Program Files\\Git\\bin\\bash.exe"`。

**Q5：Windows Terminal 里 `Alt+Enter` 是全屏，没法用作「追加消息」？**
- 这是 Windows Terminal 的默认行为。可在 Windows Terminal 设置里取消 "Alt+Enter 切换全屏" 绑定，或参考 Pi 文档 [terminal-setup.md](https://pi.dev/docs/terminal-setup) 重新映射。

**Q6：如何关闭启动时的版本检查 / 遥测？**
- 设环境变量 `PI_SKIP_VERSION_CHECK=1` 跳过版本检查；`PI_OFFLINE=1` 关闭所有启动期网络请求。
- 在 `settings.json` 设 `"enableInstallTelemetry": false` 关闭安装遥测。

**Q7：如何让某个项目用不同的模型/设置？**
- 在项目根目录建 `.pi/settings.json`，写项目级覆盖配置（如不同的 `defaultModel`），会与全局设置合并。

**Q8：密钥安全？**
- 切勿把含真实 Key 的 `models.json` / `auth.json` 提交到 Git。建议始终用 `$ARK_API_KEY` 环境变量引用，并把 `~/.pi/agent/` 排除在版本控制之外。

---

## 参考文档

- Pi 官方 README：<https://pi.dev>
- 自定义模型 `models.json`：<https://pi.dev/docs/models>
- 自定义 Provider（扩展）：<https://pi.dev/docs/custom-provider>
- Providers 与鉴权：<https://pi.dev/docs/providers>
- 设置项 `settings.json`：<https://pi.dev/docs/settings>
- Windows 安装：<https://pi.dev/docs/windows>
- 快捷键：<https://pi.dev/docs/keybindings>
