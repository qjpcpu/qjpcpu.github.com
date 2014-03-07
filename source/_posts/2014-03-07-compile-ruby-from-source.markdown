---
layout: post
title: "compile ruby from source"
date: 2014-03-07 15:35:02 +0800
comments: true
categories: ruby
---

### 下载需要的软件包

* [openssl](http://www.openssl.org/source/)
* [yaml](http://pyyaml.org/wiki/PyYAML)
* [ruby](https://www.ruby-lang.org)
* [sqlite3](http://sqlite.org/2014/sqlite-autoconf-3080301.tar.gz)(可选)

<!--more-->

假设需要安装的ruby目录为`/ruby`

### 编译openssl

	./config --prefix=/ruby  shared
	make 
	make install
	
### 编译libyaml

	./configure --prefix=/ruby
	make
	make install
	
### 编译ruby

先导入环境变量,否则ruby找不到ssl的链接目录

	export LD_LIBRARY_PATH=/ruby/lib
	export C_INCLUDE_PATH=/ruby/include
	
开始编译ruby

	./configure --prefix=/ruby --with-opt-dir=/ruby
	make
	make install
	
### 编译sqlite3(可选)
	
### 测试

	/ruby/bin/ruby -v #打印版本号，说明安装成功
	export PATH=$PATH:/ruby/bin
	