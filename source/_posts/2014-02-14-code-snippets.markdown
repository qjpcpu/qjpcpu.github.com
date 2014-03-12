---
layout: post
title: "code snippets"
date: 2014-02-14 18:08:28 +0800
comments: true
categories: shell
---

### ruby文件utf-8编码

	# -*- coding: UTF-8 -*-
	
### 退出ssh登录后继续执行命令

如果long_run_cmd是一个长时间执行的命令，而我们又想在退出ssh后不至于中断该命令：

	nohup long_run_cmd &
	
<!-- more -->


