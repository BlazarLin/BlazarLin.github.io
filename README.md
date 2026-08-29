# BlazarBlog — 个人博客源码工程

本仓库是个人博客 **[BlazarLin.github.io](https://BlazarLin.github.io/)** 的 **Hexo 源码工程**，
基于 **Hexo 6.3.0** + **Butterfly** 主题构建，通过 GitHub Pages 发布。

- 站点名称：Blazar
- 站点地址：<https://BlazarLin.github.io/>
- 文章源文件：`source/_posts/`（Markdown）
- 主题：`butterfly`（`themes/` 下另备有 `pure` 主题）

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
- 注意：`_config.yml` 中当前配置的发布分支为 `release_page`；而远端历史上实际
  承载页面的分支是 `dev`（也是仓库默认分支）。部署前请确认两边一致，避免推错分支。

## 二、目录结构

```
BlazarBlog/
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
├── source/               # 内容源文件
│   ├── _posts/           # ★ 文章 Markdown（本工程核心资产）
│   │   └── material/     # 文章引用的图片素材
│   ├── categories/ tags/ link/ img/
└── themes/
    ├── butterfly/        # 当前启用主题
    └── pure/             # 备用主题
```

## 三、当前 Git 状态备忘（2025-09 记录）

- 远端仓库仅有两个分支：
  - `dev` —— **已发布的静态页面**（默认分支），由 `hexo deploy` 强推维护；
  - `master` —— 一个历史遗留的旧源码提交，已与本地源码失去关联。
- 本地源码分支：`dev_source`（工作分支）、`dev`、`master`，三者在近期曾指向同一提交
  `c23b95a 更新主题`。
- **本地的最新源码（含大量未提交文章）此前从未推送到远端**，在把源码备份到远端
  分支之前，本机是唯一完整副本。已通过推送 `dev_source → 远端 source 分支` 完成备份。

## 四、常用命令

```bash
npm install                 # 首次使用 / 换机后安装依赖（需 Node.js）

hexo new post "文章标题"    # 新建文章 → source/_posts/文章标题.md
hexo clean                  # 清除缓存 db.json 与 public/
hexo generate               # 生成静态页面到 public/（简写 hexo g）
hexo server                 # 本地预览 http://localhost:4000（简写 hexo s）
hexo deploy                 # 部署：把 public/ 强推到发布分支（简写 hexo d）
hexo clean && hexo g && hexo d   # 完整发布流程
```

日常发布建议：`hexo clean && hexo g && hexo s` 本地确认无误后，再 `hexo d` 发布。

## 五、换机迁移指南

新电脑上从零恢复本工程：

1. **安装环境**：Node.js（Hexo 6 需 12.13+，建议 LTS 版本）、Git。
2. **克隆并切换到源码分支**：
   ```bash
   git clone https://github.com/BlazarLin/BlazarLin.github.io.git
   cd BlazarLin.github.io
   git checkout source        # 源码分支；切勿停留在发布分支上写文章
   ```
3. **安装依赖**：`npm install`
4. **配置 GitHub 凭证**（否则 push 和 hexo deploy 均被拒绝）：
   - HTTPS 方式：使用 Personal Access Token 登录，或用 GitHub CLI（`gh auth login`）；
   - SSH 方式：生成密钥并添加到 GitHub 账户，同时把 `_config.yml` 中 deploy 的
     `repository` 改为 SSH 地址。
5. **验证与发布**：
   ```bash
   hexo clean && hexo g && hexo s   # 本地预览
   hexo d                           # 发布
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
