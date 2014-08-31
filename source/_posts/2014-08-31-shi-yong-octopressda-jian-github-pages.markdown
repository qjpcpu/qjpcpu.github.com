---
layout: post
title: "使用octopress搭建github pages"
date: 2014-08-31 17:36:06 +0800
comments: true
categories: memo
---

### 安装git,ruby
==============================
略

### 安装octopress并搭建博客
==============================

```bash
git clone git://github.com/imathis/octopress.git octopresscd octopressbundle installrake install
```
<!-- more -->

初始化博客

```bash
rake setup_github_pages
```

编辑`_config.yml`写入博客名和其他信息

开始书写博客：

```bash
rake new_page["About"]    # 添加博客页rake new_post["First Post!"]  # 新建一篇文章
```

发布到github

```bash deploy.sh
rake generate      # 生成页面
#rake preview       # 如果需要在本地预览生成的结果，预览页http://localhost:4000
rake deploy        #发布到github
# 发布到github的pages在master分支，还要保存源的source分支
git add .git commit -m 'Added About page and first post!'git push origin source
```


### 在另外机器编辑博客
===========================

如果更换了电脑，在新机器上编辑写博客，不需要重新搭建一遍：

```bash get_my_blog.sh
git clone git@github.com:username/username.github.com.git
cd username.github.comgit checkout sourcemkdir _deploycd _deploygit initgit remote add origin git@github.com:username/username.github.com.gitgit pull origin mastercd ..
```