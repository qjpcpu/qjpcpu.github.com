---
layout: post
title: "shell数组"
date: 2014-03-10 00:22:25 +0800
comments: true
categories: shell
---
### 数组定义

定义数组需要用括号把元素包裹起来。

	colors=(red green blue black white)
	# 打印整个数组
	echo ${colors[*]}  # red green blue black white
	echo ${colors[@]}  # red green blue black white
	
<!--more-->

### 基本操作

	# 有两种方法获取数组长度
	echo ${#colors[@]}    # 5
	echo ${#colors[*]}    # 5
	
读写数组

	echo ${colors[0]}    # red
	colors[0]=RED
	echo ${colors[0]}    # RED
	
移除元素

	unset colors[1]
	echo ${colors[*]}    # red blue black white
	echo ${#colors[*]}   # 4
	
### 切片

切片不影响原数组

	echo ${colors[*]:1:3}    # green blue black
	# 获取切片得到的新数组
	c=(${colors[*]:1:3})
	echo ${c[*]}             # green blue black
	
### 替换

替换也不影响原数组

	echo ${colors[*]/e/E}    # rEd grEen bluE black whitE

