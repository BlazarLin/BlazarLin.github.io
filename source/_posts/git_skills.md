---
title: git—分布式版本控制工具
categories: 
- 编程工具
tags: 
- git
---
# git—分布式版本控制工具

![git_process.png](https://i.loli.net/2019/09/23/vMsT57Kucfk2QnJ.png)
<!-- TOC -->

- [git—分布式版本控制工具](#git分布式版本控制工具)
  - [1. 本地操作](#1-本地操作)
  - [2. 分支管理](#2-分支管理)
  - [3. 多人協作](#3-多人協作)
  - [4. 標籤管理](#4-標籤管理)
  - [5. 遠程庫管理](#5-遠程庫管理)
    - [5.1. 本地与远程库关联的方法](#51-本地与远程库关联的方法)
  - [6. 打包](#6-打包)
  - [7. 车祸现场](#7-车祸现场)
  - [8. 自定义git](#8-自定义git)
    - [8.1. 配置别名](#81-配置别名)

<!-- /TOC -->
## 1. 本地操作

1.廖雪峯 git Git是目前世界上最先进的分布式版本控制系统

2.git config的--global参数，用了这个参数，表示你这台机器上所有的Git仓库都会使用这个配置

3.the function of git commit -m "xxx"?? 版本修改了什麼東西 備註

$ git log显示从最近到最远的提交日志历史

$ git reset --hard HEAD^回退到上一个版本

$ git reset --hard XX(版本號)回退到XXX版本

$ git reflog用来记录你的每一次

HEAD指向的版本就是当前版本，因此，Git允许我们在版本的历史之间穿梭，使用git reset --hard commit_id
要重返未来，用git reflog查看历史，以便确定要回到未来的哪个版本

4.stage(暫存區)的概念 第一次修改 -> git add -> 第二次修改 -> git add -> git commit

5.Python編譯器:VIM Emacs Kate

總結：
cd 切換到當前目錄
$ git init 把這個目錄變成git可以管理的倉庫
(ls -ah 查看隱藏文件)

$ git add readme.txt 把文件添加到倉庫

$ git commit -m “xxx（說明的話）” 把文件提交到倉庫附上本次提交的說明

$ git status 掌握當前庫的狀態

$ git diff readme.txt 查看修改前後的difference
再次修改後進行 $ git add xx 與 $ git commit -m"xxx" 進行庫的更行

$ git log 查看提交日誌，也可查看版本號 輸入q退出查看

$ git reset --hard HEAD^ 回退到上一個版本（HEAD表示當前版本，HEAD^
表示上一個版本，HEAD^^表示上上個版本，HEAD～100表示往上100個版本）

$ git reset --hard 版本號  回到版本號對應的版本

$ git reflog用來記錄每一次

$ git stash  当前分支工作一半，需要切换分支，当前分支不想commit，进行储藏操作

$ git stash apply 恢复储藏的内容

$ git stash list 查看储藏的条目内容

$ git diff commit-id1 commit-id2 查看两个提交版本id的修改记录差异

$ git diff commit-id1 commit-id2 --stat 查看两个提交版本id修改了那些文件，可以使用

$ git commit --amend -m "new information" 覆盖上次提交的信息，即上次commit的信息会消失。

$ git config --global -l 查看本地全局配置

## 2. 分支管理

$ git checkout -- readme.txt 撤銷修改

$ git reset HEAD file 把暫存區的修改撤銷掉，用於$ git add後，想要撤銷到工作區

$ rm test.txt刪除文件 後①從版本庫中刪除 $ git rm test.txt 或②把誤刪的文件恢復到最新版本 $ git checkout -- test.txt

github
$ git remote add origin git@github.com:JockerLin/learngit.git關聯我的遠程庫

$ git pull --base origin master

$ git push -u origin master首次推送master分支的內容

$ git push origin master以後同步推送最新修改

$ git clone git@github.com:JockerLin/xx(倉庫名).git從雲端遠程庫同步到本地

$ git branch 查看分支

$ git branch <name> 創建分支

$ git checkout <name> 切換分支

$ git checkout -b <name> 創建並切換分支

$ git merge <name> 合併某分支到當前分支(fast forward的合併方式)

$ git branch -d <name> 刪除分支

$ git log 查看分支歷史

$ git log --graph --pretty=oneline --abbrev-commit 查看分支的合併情況，包含分製圖、一行顯示、提交驗證碼

$ git merge --no-ff -m "merge with no-ff" dev 禁用fast forward 普通模式合併，普通合併合併后的历史有分支，能看出来曾经做过合并，而fast forward合并就看不出来曾经做过合并。 並沒有看出來??????
bug分支測試失敗??????
feature分支 开发一个新feature，最好新建一个分支；
如果要丢弃一个没有被合并过的分支，可以通过git branch -D <name>强行删除
多人協作失敗，根據例程，helloworld.py同步成功，但是readme.txt同步失敗??????

## 3. 多人協作

1、$ git remote -v 查看遠程庫信息

2、$ git checkout -b XXX(branch-name) origin/xxx(branch-name)建立本地分支應與遠程分支名稱一致

3、$ git branch --set-upstream xxx(branch-name) origin/xxx(branch-name)建立本地分支與遠程分支的關聯

4、$ git push origin xxx(branch-name)推送自己的修改；

5、若推送失敗，因爲遠程分支版本比本地新，需要先用$ git pull試圖合併；或$ git pull --rebase origin master

6、合併有衝突，解決衝突後在本地提交；

7、解決後無衝突，再用步驟1則推送成功；
（若$ git pull提示"no tracking information"，應先建立本地分支與遠程分支的鏈接關係$ git branch --set-upstream branch-name origin/branch-name）

## 4. 標籤管理

$ git tag xxx<標簽名> 新建標籤 默認爲HEAD
$ git tag xxx<標簽名> xxx<commit id>   新建標籤
$ git tag 查看所有標籤
$ git tag -a xxx<標簽名> -m "xxx<標籤信息>"
$ git show xxx<標簽名> 查看標籤信息
$ git push origin xxx<標簽名> 推送一個本地標籤
$ git push origin --tags 推送全部未接受過的本地標籤
$ git tag -d xxx<標簽名> 刪除本地標籤
$ git push origin :refs/tags/xxx<標簽名> 刪除一個遠程標籤

錯誤修改 git add .

## 5. 遠程庫管理

$ git remote -v  查看遠程庫信息
$ git remote rm origin  刪除已有的遠程庫

創建刪除新用戶
$ sudo adduser xxx 在home目錄下添加一個賬號
$ sudo useradd xxx 僅添加普通用戶，不會再home目錄下添加賬號
$ sudo useadd -g root 用戶名 /* 讓剛剛建立的用戶劃分到root權限組下
$ sudo usedel -r newuser 刪除名爲newuser的用戶

每个机器都必须自报家门：你的名字和Email地址。你也许会担心，如果有人故意冒充别人怎么办？这个不必担心，首先我们相信大家都是善良无知的群众，其次，真的有冒充的也是有办法可查的。
$ config --global user.name "Your Name"
$ git config --global user.email "email@example.com"
注意git config的--global参数，用了这个参数，表示你这台机器上所有的Git仓库都会使用这个配置，当然也可以对某个仓库指定不同的用户名和Email地址。

$ git remote show origin 查看远程库的origin的信息

$ git branch -a 查看本地所有分支，红色部分为远程库在本地的copy版本

$ git remote prune origin 更新本地上的远程库版本（删除不存在的分支）

$ git remote prune 删除本地版本库上那些失效的远程追踪分支

$ git branch -vv

$ git push origin :分支名字 删除远端分支

$ git push origin --delete 分支名字 删除远端分支

$ git config --add core.filemode false 忽略文件的chmod修改导致的git diff

git工程创建后，开发过程中加入.gitignore或更改git配置需要立即生效，则需要清除暂存区staged文件

```shell
git rm -r --cached .
git add .
git commit -m 'update .gitignore'
```

### 5.1. 本地与远程库关联的方法

1、在gitlab或者github新建工程 本地拉取
2、远程已经有工程了 本地工程重新整理后

```shell
git init #初始化
git remote remove origin # 删除关联的远程库
git add .
git commit -m 'update xxx'
git remote add origin https://github.com/JockerLin/Notes #重新关联or添加本地库对应的远程库，
git fetch
git merge # 可能需要解决冲突 不同步的问题
#即可正常push
```

单独添加远程仓库

一个本地仓库可以对应多个远程仓库

```shell
git remote add origin https://github.com/JockerLin/Notes #重新关联or添加本地库对应的远程库
```

## 6. 打包



## 7. 车祸现场

1、

git push 或 git fetch 的时候 报connect的错误信息：

```shell
pilcq@creater:~/test/VisionTool_PY$ git fetch origin develop:develop

>>>fatal: unable to access 'http://192.168.16.210:10080/lu_sa/VisionTool_PY.git/': >>>Failed to connect to 127.0.0.1 port 1080: Connection refused
```

查询后发现可能是翻墙的时候代理没clear干净导致

```shell
pilcq@creater:~/test/VisionTool_PY$ env|grep -i proxy
>>>http_proxy=http://127.0.0.1:1080/
>>>https_proxy=https://127.0.0.1:1080/

# 将两个代理清除干净
pilcq@creater:~/test/VisionTool_PY$ export http_proxy=""
pilcq@creater:~/test/VisionTool_PY$ export https_proxy=""

#再查看
pilcq@creater:~/test/VisionTool_PY$ env|grep -i proxy
>>>http_proxy=
>>>https_proxy=

#清除代理成功，fetch 与 push 恢复正常

```

## 8. 自定义git

### 8.1. 配置别名

用co表示checkout，ci表示commit，br表示branch：

```shell
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.br branch
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

```
