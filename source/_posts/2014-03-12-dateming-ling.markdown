---
layout: post
title: "date命令"
date: 2014-03-12 23:03:56 +0800
comments: true
categories: shell
---

首先看看常用的格式字符串

	 %Y 年
	 %m 月
	 %d 日
	 %H 时
	 %M 分
	 %S 秒
	 %s 时间戳(秒)

**date命令常用操作**

获取当前时间

	date +%Y-%m-%d    # 2014-02-21
	
<!--more-->

几天前(后)，几月前(后)，几年前(后)

	date -d "1 day ago"  "+%Y-%m-%d %H:%M:%S"  #一天前的当前时间 2014-02-20 11:11:31
	date -d "2 days ago"  # 或者date-d "-2 days"
	date -d "-8 months"
	date -d "+2 years" # 两年后

多少分钟，小时前（后）
	
	date -d "-5 minutes"  "+%Y-%m-%d %H:%M:%S"  #5分钟前
	date -d "5 minutes"  "%H:%M:%S"  #5分钟后

时间戳和日期互转，常用于计算

	date -d "2014-02-20 11:11:31" +%s  #获取某时间的时间戳
	date +%s   #返回当前时间戳1392954893
	date -d @1392954893 "+%Y-%m-%d %H:%M:%S"  #将时间戳转换为时间
