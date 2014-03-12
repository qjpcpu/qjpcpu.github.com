---
layout: post
title: "stat命令与文件时间"
date: 2014-03-12 15:04:54 +0800
comments: true
categories: shell
---

### stat命令

stat命令常用来获取文件三个时间`access time`,`modify time`和`change time`

	$ stat access.log
	  File: `access.log'
	  Size: 1559877779	Blocks: 3049624    IO Block: 4096   regular file
	Device: ca20h/51744d	Inode: 16269326    Links: 1
	Access: (0644/-rw-r--r--)  Uid: (  500/    work)   Gid: (  500/    work)
	Access: 2014-03-09 21:58:33.000000000 +0800
	Modify: 2014-03-07 08:17:36.000000000 +0800
	Change: 2014-03-07 08:17:36.000000000 +0800
	
通常可以使用`-c`参数直接获取三个时间

	$ stat -c %x access.log   #获取access time
	2014-03-09 21:58:33.000000000 +0800
	$ stat -c %y access.log  #获取modify time
	2014-03-07 08:17:36.000000000 +0800
	$ stat -c %z access.log #获取change time
	2014-03-07 08:17:36.000000000 +0800
	
<!--more-->
	
### 三个时间

`access time`对应文件访问时间，只要有读操作就会更新这个时间。

`change time`对应文件元信息，比如文件重命名会更新该时间。

`modify time`对应文件内容修改时间，只要修改文件内容就会更新该时间，由于内容改变实际也改变文件元数据，所以写操作也更新`change time`。

注意：对于文件夹来说，对文件夹下的文件增删，重命名，等操作，会修改文件夹`change time`和`modify time`，因为文件名实际是作为目录文件的内容存在的。