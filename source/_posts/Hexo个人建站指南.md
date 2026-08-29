---
title: Hexo个人建站指南
categories: 
- 编程工具
tags: 
- web前端
---

### 常用组合命令
`hexo s -g` #生成并本地预览

`hexo d -g` #生成并上传

`hexo clean` #清空本地缓存

`hexo clean && hexo g && hexo s`


### markdown标题头配置
``` bash
title: 文章标题
date: 2024-02-10 14:47:40
categories: 分类(只能单个)
tags:
  - 标签一(可以多个)
  - 标签二
```

### 设置显示数学公式

#### 方法1
Hexo当中的数学公式插入问题
hexo已经把hexo-math整合到了hexo里面，所以你不需要再去单独装一些东西。你要做的事情就是，打开themes->*你的主题，我这里是next*->_config.yml

#### 方法2
找到math这一段
把mathjax 下面的enable: false 改成 true

``` bash
# Math Formulas Render Support
# Warning: Please install / uninstall the relevant renderer according to the documentation.
# See: https://theme-next.js.org/docs/third-party-services/math-equations
# Server-side plugin: https://github.com/next-theme/hexo-filter-mathjax
math:
  # Default (false) will load mathjax / katex script on demand.
  # That is it only render those page which has `mathjax: true` in front-matter.
  # If you set it to true, it will load mathjax / katex srcipt EVERY PAGE.
  every_page: false

  mathjax:
    enable: false
    # Available values: none | ams | all
    tags: none
```
然后在你要插入数学公式的那个markdown源文件里在front-matter（也就是每一个post的最开头那里，加上一行 mathjax: true）就好了！！！ （一定要半角: 接一个空格）

``` bash
title: Stokes_Theorem
date: 2022-07-20 15:20:42
tags:
mathjax: true

```
在markdown行内公式里千万不要 $+空格 要不然会渲染失败。

### 配置自定义域名

在source下新建CNAME文件

内容为自定义域名

www.blazar.life

阿里云增加自定义域名的解析记录

1. 记录类型要选择`CNAME`(直接指向另一个域名)，记录值为指向的目标网址`jockerlin.github.io`，增加两种主机记录为`@`与`www`

2. 在githubPage设置中增加自定义域名的名称，github会自动检查DNS是否有效，出现`DNS check successful`则添加成功。



### 参考
[Windows 环境下 Hexo+Github 搭建个人博客教程](https://sunyunzeng.com/%E5%8D%9A%E5%AE%A2%E6%90%AD%E5%BB%BA%E6%95%99%E7%A8%8B/)

[win10使用Hexo+GitHub搭建个人博客](https://www.cnblogs.com/debugxw/p/11006734.html)

[Butterfly 安裝文檔](https://butterfly.js.org/posts/4aa8abbe/)

