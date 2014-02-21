---
layout: post
title: "linux日常维护"
date: 2014-02-21 22:58:13 +0800
comments: true
categories: linux
---

### 某些用户cron任务失败

有时某些普通用户的crontab任务会失败，这可能是由于crond执行普通用户的任务时，是以非登录shell的形式切换到普通用户来执行的，所以可能缺失了某些环境变量。

解决办法是在crontab任务前先执行`source /home/username/.bash_profile`，后面再接用户自己的任务命令即可。

ps.`/etc/profile`,`~/.bash_profile`,`~/.bashrc`三个脚本的区别：

* /etc/profile     #系统级初始化脚本，会被登录shell执行
* ~/.bash_profile  #用户配置，会被登录shell执行，非登录shell不执行
* ~/.bashrc        #非登录shell执行，但通常~/.bash_profile都会在代码里调用~/.bashrc，所以登录shell也执行它

<!--more-->