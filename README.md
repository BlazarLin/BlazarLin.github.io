# BlazarBlog — 个人博客源码工程

本仓库是个人博客 **[BlazarLin.github.io](https://BlazarLin.github.io/)** 的 **Hexo 源码工程**，
基于 **Hexo 6.3.0** + **Butterfly** 主题构建，通过 GitHub Pages 发布。

- 站点名称：Blazar
- 站点地址：<https://BlazarLin.github.io/>
- 文章源文件：`source/_posts/`（Markdown）
- 主题：`butterfly` 5.7.0（Git 子模块固定版本，`themes/` 下另备有 `pure` 主题）

---

## 一、与发布网页的关系（双分支机制）

本工程与线上网页共用一个 GitHub 仓库（`BlazarLin/BlazarLin.github.io`），
通过 **分支分离源码与发布页面**：

```
写文章 (source/_posts/*.md)
      │
      ▼  hexo generate
渲染生成静态页面 (public/)
      │
      ▼  hexo deploy  (hexo-deployer-git, 经 .deploy_git/ 仓库)
强推到 GitHub 仓库的发布分支
      │
      ▼
GitHub Pages 从发布分支发布 → https://BlazarLin.github.io/
```

- **源码分支**（本分支）：存放 Markdown 文章、主题配置、脚手架等源文件，**不包含**生成的网页。
- **发布分支**（远端 `dev`）：存放 `hexo deploy` 推送上去的纯静态 HTML，提交信息形如
  `Site updated: 2025-08-31 09:50:11`，由 GitHub Pages 直接对外服务。
- `.deploy_git/` 是 `hexo-deployer-git` 的工作仓库（已 gitignore），每次部署时基于
  `public/` 生成一次提交并强制推送，在原分支被 force-push 覆盖属正常现象。
- `_config.yml` 中的发布分支固定为远端 `dev`。一键发布脚本只在独立的
  `.deploy_git/` 仓库中提交并推送静态网页，不会切换本地主仓库的 `dev_source` 分支，
  也不会自动执行源码的 `git add`、`git commit` 或 `git push`。

## 二、目录结构

```
BlazarBlog/
├── .gitmodules           # Butterfly 主题子模块地址
├── .deploy_git/          # hexo deploy 专用 git 仓库（自动生成，已忽略）
├── .github/              # GitHub 相关配置
├── .gitignore            # 忽略 node_modules / public / db.json / .deploy* 等
├── _config.yml           # Hexo 主配置（站点名、URL、部署方式等）
├── _config.butterfly.yml # Butterfly 主题独立配置（覆盖主题默认值）
├── db.json               # Hexo 缓存数据库（自动生成，已忽略）
├── package.json          # 依赖清单（hexo 6.3.0 及各插件）
├── node_modules/         # npm 依赖（自动安装，已忽略）
├── public/               # hexo generate 生成产物（已忽略）
├── scaffolds/            # 模板：post / draft / page
├── 一键本地预览.bat      # 启动 Hexo Server 并打开浏览器
├── 一键发布网页.bat      # 构建并部署到远端 dev 分支
├── source/               # 内容源文件
│   ├── _posts/           # ★ 文章 Markdown（本工程核心资产）
│   │   └── material/     # 文章引用的图片素材
│   ├── categories/ tags/ link/ img/
└── themes/
    ├── butterfly/        # 当前启用主题，固定为 5.7.0
    └── pure/             # 备用主题
```

## 三、Git 分支职责

- 远端仓库当前有三个分支：
  - `dev` —— **已发布的静态页面**（默认分支），由 `hexo deploy` 强推维护；
  - `dev_source` —— 博客源码备份分支；
  - `master` —— 一个历史遗留的旧源码提交，已与本地源码失去关联。
- 本地日常写作和配置修改只在 `dev_source` 进行；本地 `dev` 用于对应远端网页分支，
  不应在其中编辑文章。
- `origin/HEAD` 指向 `origin/dev`，因此克隆后必须显式切换到 `dev_source` 再修改源码。

## 四、常用命令

```bash
npm ci                      # 按 package-lock.json 可复现安装依赖（需 Node.js）

hexo new post "文章标题"    # 新建文章 → source/_posts/文章标题.md
hexo clean                  # 清除缓存 db.json 与 public/
hexo generate               # 生成静态页面到 public/（简写 hexo g）
hexo server                 # 本地预览 http://localhost:4000（简写 hexo s）
hexo deploy                 # 部署：把 public/ 强推到发布分支（简写 hexo d）
hexo clean && hexo g && hexo d   # 完整发布流程
```

日常发布建议：`hexo clean && hexo g && hexo s` 本地确认无误后，再 `hexo d` 发布。

### 双击脚本

| 脚本 | 行为 | 是否修改远端 |
|------|------|--------------|
| `一键本地预览.bat` | 检查环境和主题，启动 `hexo server --open`，打开 <http://localhost:4000/> | 否 |
| `一键发布网页.bat` | 检查 `dev_source`、安装依赖、执行 clean / generate / deploy | 是，只更新远端 `dev` 网页分支 |

发布脚本还提供只构建、不部署的验证模式：

```bat
一键发布网页.bat --build-only
```

预览窗口关闭或按 `Ctrl+C` 后服务停止。两个批处理文件的正文使用纯 ASCII 提示，
是为了避免 Windows `cmd.exe` 在 UTF-8 中文批处理中的代码页解析错误；中文文件名不受影响。

### 发布排错要点

- **部署到错误分支**：远端实际网页分支是 `dev`，原 `_config.yml` 曾写成不存在的
  `release_page`。发布前应同时核对 `_config.yml` 与 `git ls-remote --heads origin`。
- **误以为 deploy 会切换本地分支**：`hexo deploy` 使用 `.deploy_git/` 独立仓库；
  主仓库应始终留在 `dev_source`。发布脚本在运行前后都会校验分支，而且不自动提交源码。
- **批处理明明存在却被 CMD 当成乱码命令**：UTF-8 中文正文在部分 `cmd.exe` 环境会被错误解析。
  脚本因此使用 ASCII 命令和提示；不要仅依赖 `chcp 65001` 解决批处理文件解析问题。
- **`findstr` 正则判断配置失败**：Windows `findstr` 的正则能力有限，空白表达式与常见正则引擎
  行为不同。检查部署分支时使用固定文本 `branch: dev`，不要使用复杂空白正则。
- **所有 Markdown 报 `pandoc exited with code null`**：`hexo-renderer-pandoc` 依赖系统安装
  `pandoc.exe`。当前工程已改用纯 npm 的 `hexo-renderer-marked`，换机不再依赖系统 Pandoc。
- **Hexo 返回成功但生成空站**：主题目录缺少 layout 时，日志会大量出现 `No layout`，
  `hexo generate` 仍可能返回成功，同时 `public/index.html` 为 0 字节。发布脚本会额外校验首页
  存在且非空，失败时禁止 deploy。
- **Butterfly 目录为空，子模块无法初始化**：原仓库只有 gitlink，缺少 `.gitmodules`，且旧提交
  不存在于 Butterfly 官方仓库。现已补充官方子模块地址并固定 5.7.0；两个脚本在布局缺失时
  会恢复该版本。

## 五、换机迁移指南

新电脑上从零恢复本工程：

1. **安装环境**：Node.js（Hexo 6 需 12.13+，建议 LTS 版本）、Git。
2. **克隆并切换到源码分支**：
   ```bash
   git clone https://github.com/BlazarLin/BlazarLin.github.io.git
   cd BlazarLin.github.io
   git checkout dev_source    # 源码分支；切勿停留在 dev 发布分支上写文章
   ```
3. **恢复主题与依赖**：
   ```bash
   git submodule update --init --depth 1 -- themes/butterfly
   npm ci
   ```
   也可以直接双击预览或发布脚本，由脚本自动恢复缺失的 Butterfly 5.7.0 和 npm 依赖。
4. **配置 GitHub 凭证**（否则 push 和 hexo deploy 均被拒绝）：
   - HTTPS 方式：使用 Personal Access Token 登录，或用 GitHub CLI（`gh auth login`）；
   - SSH 方式：生成密钥并添加到 GitHub 账户，同时把 `_config.yml` 中 deploy 的
     `repository` 改为 SSH 地址。
5. **验证与发布**：
   ```bash
   一键发布网页.bat --build-only    # 只生成并检查首页，不更新远端
   一键本地预览.bat                 # 浏览器预览
   一键发布网页.bat                 # 确认后发布到远端 dev
   ```

> 无需手工拷贝 `node_modules/`、`public/`、`db.json`、`.deploy_git/`，
> 它们均在 `.gitignore` 中，会在新机器上自动重建。

## 六、写作须知

- 文章放在 `source/_posts/`，文件头使用 Front-matter（title / date / tags / categories 等）。
- 文章引用的图片统一放 `source/_posts/material/`，用相对路径引用。
- 中文文件名可直接使用，但注意部分环境对中文路径的兼容性；已收录的历史文章
  即为中文命名，保持风格一致即可。
- 修改站点级配置改 `_config.yml`，修改主题外观改 `_config.butterfly.yml`，
  不要直接改动 `themes/butterfly/` 内部文件，以免主题升级时丢失定制。
