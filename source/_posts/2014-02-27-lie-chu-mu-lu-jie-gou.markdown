---
layout: post
title: "列出目录结构"
date: 2014-02-27 20:52:50 +0800
comments: true
categories: shell
---

### 最简单美观的方法tree

tree命令是专门用来罗列目录结构的，输出树形结果，很漂亮。

```bash
$ tree demo
demo
├── Gemfile
├── boot.rb
├── collectors
├── config
│   └── mail_config.rb
├── controllers
├── db
│   ├── connection.rb
│   ├── database.yml
│   └── migrate
├── helpers
├── models
├── rakefile
└── views

8 directories, 6 files
```
<!--more-->

### 折衷的方法find

如果没有权限在机器上安装tree命令，find命令也是一种折衷的选择。

```bash
$ find demo -type f -o -type d
demo
demo/boot.rb
demo/collectors
demo/config
demo/config/.gitkeep
demo/config/mail_config.rb
demo/controllers
demo/db
demo/db/connection.rb
demo/db/database.yml
demo/db/migrate
demo/db/migrate/.gitkeep
demo/Gemfile
demo/helpers
demo/helpers/.gitkeep
demo/models
demo/rakefile
demo/views
```

虽然没有tree命令那么直观，但却有另一个好处，便于使用管道进一步操作。

### 仅仅是一种选择ls

ls命令也可以罗列出目录结构，但这个仅供娱乐了。

```bash
$ ls -R demo
Gemfile		collectors	controllers	helpers		rakefile
boot.rb		config		db		models		views

demo/collectors:

demo/config:
mail_config.rb

demo/controllers:

demo/db:
connection.rb	database.yml	migrate

demo/db/migrate:

demo/helpers:

demo/models:

demo/views:
```
