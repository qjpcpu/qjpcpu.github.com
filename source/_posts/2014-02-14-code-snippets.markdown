---
layout: post
title: "code snippets"
date: 2014-02-14 18:08:28 +0800
comments: true
categories: script
---

### ruby文件utf-8编码

	# -*- coding: UTF-8 -*-
	
### 退出ssh登录后继续执行命令

如果long_run_cmd是一个长时间执行的命令，而我们又想在退出ssh后不至于中断该命令：

	nohup long_run_cmd &
	
<!-- more -->

### date命令常用操作 

``` bash
date +%Y-%m-%d    #2014-02-21
date -d "1 day ago"  "+%Y-%m-%d %H:%M:%S"  #一天前的当前时间 2014-02-20 11:11:31
date -d "-5 minutes"  "+%Y-%m-%d %H:%M:%S"  #5分钟前
date -d "5 minutes"  "%H:%M:%S"  #5分钟后
date -d "2014-02-20 11:11:31" +%s  #获取某时间的时间戳
date +%s   #返回当前时间戳1392954893
date -d @1392954893 "+%Y-%m-%d %H:%M:%S"  #将时间戳转换为时间
```
