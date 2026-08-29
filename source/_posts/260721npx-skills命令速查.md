---
title: npx skills 命令速查
categories:
- 编程工具
tags:
- skills
- npm
- AI编程工具
---

# npx skills 命令速查

<!--
创建时间: 2026-07-21
功能: skills CLI（npm 包 skills，来自 skills.sh）常用命令速查
目的: 忘记时快速检索命令与参数含义
工具版本: skills@latest（用 npx 拉取，无需全局安装）
-->

> 一行速记：`npx skills@latest <command> [options]`
> 官网: https://skills.sh/
> 帮助: `npx skills@latest --help` / `npx skills@latest add --help`

---

## 一、最常用命令（先记这些）

### 安装
```bash
# 全局装某仓库全部 skill 到 codex，无人值守
npx skills@latest add <owner>/<repo> -g -a codex --skill "*" -y

# 项目级装（仅当前项目）
npx skills@latest add <owner>/<repo> -a codex --skill "*" -y

# 先看仓库里有哪些 skill，不安装
npx skills@latest add <owner>/<repo> -l
```

### 查看
```bash
npx skills@latest ls -g -a codex     # 看全局下 codex 装了啥
npx skills@latest ls --json          # 机器可读（无 ANSI 颜色码）
```

### 卸载
```bash
npx skills@latest remove <skill> -g -a codex   # 卸载指定
npx skills@latest rm --all -g                  # 清空全局（慎）
```

### 更新
```bash
npx skills@latest update -g -y       # 更新全局全部
npx skills@latest update <skill>     # 更新单个
```

---

## 二、add 参数详解（最常用子命令）

| 参数 | 全称 | 含义 |
|---|---|---|
| `-g` | `--global` | 全局（用户级）安装，跨项目可用；不加则项目级 |
| `-a <agents>` | `--agent` | 目标 agent，可多个；`*` 表全部（codex/claude-code/cursor...）|
| `-s <skills>` | `--skill` | 指定 skill 名，`*` 表全部；可多个（空格分隔）|
| `-l` | `--list` | 只列出仓库内可用 skill，不安装 |
| `-y` | `--yes` | 跳过确认提示（无人值守）|
| `--copy` | — | 复制文件到 agent 目录，而非默认 symlink |
| `--all` | — | 简写 = `--skill '*' --agent '*' -y`（装到**所有** agent）|
| `--full-depth` | — | 即使根目录有 SKILL.md，也搜索所有子目录 |
| `--subagent <names>` | — | 装到 Eve 子 agent（`root` 表根 agent）|
| `--metadata <json>` | — | 给安装遥测事件附加 JSON（一般不用）|

### 全局选项
- `--help` / `-h`：帮助
- `--version` / `-v`：版本

---

## 三、子命令一览

| 命令 | 别名 | 作用 |
|---|---|---|
| `add <package>` | `a` | 安装 skill 包 |
| `use <package>@<skill>` | — | 不安装，生成使用 prompt（可管道给 agent）|
| `remove [skills]` | `rm` | 卸载 skill |
| `list` | `ls` | 列出已装 skill |
| `find [query]` | — | 交互式搜索；`--owner <owner>` 限定 GitHub owner |
| `update [skills...]` | `upgrade` | 更新到最新版本 |
| `init [name]` | — | 初始化新 skill（生成 `<name>/SKILL.md`）|
| `experimental_install` | — | 从 `skills-lock.json` 恢复（类 `npm ci`，可复现）|
| `experimental_sync` | — | 从 `node_modules` 同步到 agent 目录 |

### 其他子命令的常用参数
- **update**: `-g` 仅全局 / `-p` 仅项目 / `-y` 跳过 scope 选择
- **remove**: `-g` 全局 / `-a <agents>` / `-s <skills>` / `--all` 全清
- **list**: `-g` 看全局（默认项目级）/ `-a <agent>` 过滤 / `--json`
- **find**: `--owner <owner>` 限定仓库 owner
- **experimental_sync**: `-a <agents>` / `-y`

---

## 四、场景速查（想做什么 → 用什么）

| 场景 | 命令 |
|---|---|
| 全局装 codex 全部 skill | `add <repo> -g -a codex --skill '*' -y` |
| 只装某几个 skill | `add <repo> -a codex --skill a b c` |
| 装到多个 agent | `add <repo> -a codex claude-code --skill '*'` |
| 先看仓库有啥再决定 | `add <repo> -l` |
| 临时用一次不装 | `use <repo>@<skill> \| codex` |
| 看全局装了啥 | `ls -g -a codex` |
| 卸载某个 | `remove <skill> -g -a codex` |
| 一键更新全部 | `update -g -y` |
| 团队可复现环境 | `experimental_install`（配合 `skills-lock.json`）|
| 冻结、不被源更新影响 | `add --copy`（默认 symlink 会跟随源更新）|
| 初始化自己的 skill | `init my-skill` |

---

## 五、关键区分（易混淆点）

1. **`--all` ≠ `-a codex --skill '*' -y`**：`--all` 会装到**所有 agent**（claude-code/cursor/codex 全部）。只装 codex 时**不要**用 `--all`，要显式 `-a codex`。
2. **symlink（默认）vs `--copy`**：默认 symlink，源仓库更新后链接自动生效；`--copy` 是复制快照，冻结当前版本。
3. **全局 `-g` vs 项目级**：全局装到用户目录跨项目可用；项目级仅当前项目（团队共享时配合 `skills-lock.json`）。
4. **`-y` 跳过确认**：适合脚本/无人值守；交互调试时**不加** `-y` 可看到具体动作。
5. **`use` vs `add`**：`use` 不落地、生成 prompt 临时试用；`add` 持久安装到 agent 目录。
6. **`npx --yes` 与 skills 的 `-y`**：`npx` 首次拉包有自己的安装确认，用 `npx --yes skills@latest ...` 跳过 npx 那层；skills 自己的 `-y` 跳过 skills 的确认。两层独立。

---

## 六、典型工作流

### 流程A：发现并安装一个 skill 仓库
```bash
npx --yes skills@latest add BlazarLin/EfficiencySkill -l        # 1. 先列
npx --yes skills@latest add BlazarLin/EfficiencySkill -g -a codex --skill "*" -y  # 2. 全局装
npx --yes skills@latest ls -g -a codex                          # 3. 确认
```

### 流程B：临时试用不污染环境
```bash
npx --yes skills@latest use BlazarLin/EfficiencySkill@<skill-name> | codex
```

### 流程C：团队可复现
```bash
# 提交 skills-lock.json 到仓库
npx --yes skills@latest experimental_install    # 其他人拉代码后一键恢复
```

---

## 七、备注

- `<owner>/<repo>` 也可用完整 URL：`https://github.com/<owner>/<repo>`
- skill 安装位置：全局在用户级 agent 配置目录（codex 一般在 `~/.codex/` 下），项目级在当前项目内
- `skills` 包本身通过 `npx` 临时拉取执行，无需 `npm install -g`
- 数据来源：`npx skills@latest --help` 实测输出（2026-07-21）
