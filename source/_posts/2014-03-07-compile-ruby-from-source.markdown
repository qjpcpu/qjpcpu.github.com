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

假设需要安装的ruby目录为`/path/to/ruby_dir`

    export RUBY_DEST=/path/to/ruby_dir

### 编译openssl

	./config --prefix=$RUBY_DEST  shared
	make 
	make install
	
### 编译libyaml

	./configure --prefix=$RUBY_DEST
	make
	make install

### 编译pkg-config(如果版本过低需要安装，否则编译ruby会报错`Unknown keyword 'URL' in '.$RUBY_DEST.tmp.pc'`)

	./configure --prefix=$RUBY_DEST         \
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

	export LD_LIBRARY_PATH=$RUBY_DEST/lib
	export C_INCLUDE_PATH=$RUBY_DEST/include
	
开始编译ruby

	./configure --prefix=$RUBY_DEST --with-opt-dir=$RUBY_DEST
	make
	make install
	
### 编译sqlite3(可选)
	
### 测试

	$RUBY_DEST/bin/ruby -v #打印版本号，说明安装成功
	export PATH=$PATH:$RUBY_DEST/bin
	
