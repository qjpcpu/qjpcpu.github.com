---
layout: post
title: "shell字符串处理"
date: 2014-02-14 18:10:30 +0800
comments: true
categories: shell
---

###1.获取字符串长度

    
	${#string}

-

	[jason@localhost ~]$ str="hello,world"
	[jason@localhost ~]$ echo ${#str}
	11

###2.获取子串

	${string:position}
	${string:position:length}
	$(string:(-postion)) 如果使用负数，表示从右开始计数，注意负数必须使用括号
-

	[jason@localhost ~]$ str=ABCDEFGHIJKLMN
	[jason@localhost ~]$ echo ${str:1}
	BCDEFGHIJKLMN
	[jason@localhost ~]$ echo ${str:1:2}
	BC
	[jason@localhost ~]$ echo ${str:(-2)}
	MN

<!-- more -->

###3.子串切除

	${string#substring} 从左向右切除最短匹配的子串
	${stirng##substring} 从左向右切除最长匹配的子串
	${string%substring} 从右向左切除最短匹配的子串
	${stirng%%substring} 

###4.字符串正则提取

	echo $string | grep -oE "regexpression”
-

	[jason@localhost ~]$ str="I am 12 years old"
	[jason@localhost ~]$ echo $str | grep -Eo '[0-9]+'
	12

###5.字符串正则替换

	echo $string | sed -r 's/regexpr/replacement'
-

	[jason@localhost ~]$ str="I am 12 years old" 
	[jason@localhost ~]$ echo $str | sed -r  "s/ am/'m/"
	I'm 12 years old

###6.分割字符串

	awk

-

	[jason@localhost ~]$ str="I_am_12_years_old, and you?"
	[jason@localhost ~]$ echo $str | awk -F '_' '{print $3}'
	12
	[jason@localhost ~]$ echo $str | awk  '{split($1,a,"_");print a[3]}'
	12

###7. 获取索引

	awk '{print match($0,"substring")}'

-

	[jason@localhost ~]$ str="I_am_12_years_old, and you?"
	[jason@localhost ~]$ echo $str | awk '{print match($0,"[0-9]+")}'
	6

注意这个索引是从1开始的

###8.sed分组

sed的分组是很好玩的，在替换模式中，“&”代表前面匹配的全部字符串，而反斜杠加数字表示分组。

	[jason@localhost ~]$ str="name:jack;age:12"
	[jason@localhost ~]$ echo $str | sed -r 's/name:[^;]+/[&]/'
	[name:jack];age:12
	[jason@localhost ~]$ echo $str | sed -r 's/name:([^;]+)/--\1--/'
	--jack--;age:12

###9.awk常用字符串处理函数

	sub(reg,replacement,string)
	gsub(reg,replacement,string)

将string中匹配正则表达式reg的字符串（全部）替换为replacement

	[jason@localhost ~]$ str="name:jack;age:12"
	[jason@localhost ~]$ echo $str | awk '{gsub(/a/,"A",$0);print $0}'      
	nAme:jAck;Age:12

-

	index(substring,string) #返回子字符串substring在字符串string中的位置
	length(string) #获取字符串的长度
	match(string,reg) #获取匹配reg得到的子串在字符串中的位置
	split(string,array,separator) #将字符串按分隔符separator分割到array数组中
	sprintf("format",expression) #和c语言的sprintf类似
	substr(string,position,length)  #获取子字符串
	tolower(string)
	toupper(string)
