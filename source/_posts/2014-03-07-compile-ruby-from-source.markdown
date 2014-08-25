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
* [pkg-config](http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz)(可选)

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

### 编译pkg-config(如果版本过低需要安装，否则编译ruby会报错`Unknown keyword 'URL' in './ruby.tmp.pc'`)

	./configure --prefix=/ruby         \
	            --with-internal-glib  \
	            --disable-host-tool
	
如果报错：

	gthread-posix.c: In function `g_system_thread_set_name':
	gthread-posix.c:1175: error: `PR_SET_NAME' undeclared (first use in this function)
	gthread-posix.c:1175: error: (Each undeclared identifier is reported only once
	gthread-posix.c:1175: error: for each function it appears in.)

就需要在pkg源码目录下glib/glib/gthread.c添加：


	#define PR_SET_NAME    15               /* Set process name */
	#define PR_GET_NAME    16               /* Get process name */

然后再继续编译

	make && make install
	
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
	