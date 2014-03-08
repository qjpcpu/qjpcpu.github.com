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
	
	#awk的match方法利用RSTART和RLENGTH分别保存匹配的起点(从1开始)和匹配到的长度,RSTART同时也是match方法的返回值，如果没找到则RSTART==0,RLENGHT==-1
	echo $string | awk '{ match($0,"reg"); print substr(RSTART,RLENGTH)}'
-

	[jason@localhost ~]$ str="I am 12 years old"
	[jason@localhost ~]$ echo $str | grep -Eo '[0-9]+'
	12
	[jason@localhost ~]$ str="I am 12 years old"
	[jason@localhost ~]$ echo $str | awk '{ if(match($0,"[0-9]+")){ print substr($0,RSTART,RLENGTH) } }'
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

###9.awk专题

**常用字符串处理函数**

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
	
**awk的常见控制语法**

	exit #退出awk执行
	next #跳转到命令块首，并开始下一行数据读入
	NF #列数
	NR #行号
	FS #分隔符
	FILENAME #文件名
	
**给awk传递shell变量值**

方法一：`awk '{action}' name1=val1 name2=val2 file`，变量值无法在`BEGIN`中获得

	$ var="SHELL"
	$ awk 'BEGIN{print a}{print a}END{print a}' a=$var file
	#输出
	
	SHELL
	
方法二：`awk -v name=value '{action}' file`，变量在三种块中都可以获得

	$ var="SHELL"
	$ awk -v a=$var 'BEGIN{print a}{print a}END{print a}' file
	#输出
	SHELL
	SHELL
	SHELL
	
P.S.awk获取环境变量

	$ awk 'BEGIN{print ENVIRON["LANG"]}' -
	en_US

**awk中调用shell命令**
	
awk中调用shell命令，使用`system()`函数，被引号括起来的内容会直接发送给shell，而没有括起来的部分被当做awk当中的变量替换

	$ awk 'BEGIN{a="AWK";system("echo "a)}' -
	AWK
	
awk中支持的正则表达式是ERES,它包含下列特殊符号：

* **+**, 指定如果一个或多个字符或扩展正则表达式的具体值（在 +（加号）前）在这个字符串中，则字符串匹配。
* **?**,	指定如果零个或一个字符或扩展正则表达式的具体值（在 ?（问号）之前）在字符串中，则字符串匹配
* **|**	, 指定如果以 |（垂直线）隔开的字符串的任何一个在字符串中，则字符串匹配。
* **( )**,	在正则表达式中将字符串组合在一起。
* **{m}**,	指定如果正好有 m 个模式的具体值位于字符串中，则字符串匹配。
* **{m,}**,	指定如果至少 m 个模式的具体值在字符串中，则字符串匹配
* **{m, n}**, 	指定如果 m 和 n 之间（包含的 m 和 n）个模式的具体值在字符串中（其中m <= n），则字符串匹配。
* **[String]**,	指定正则表达式与方括号内 String 变量指定的任何字符匹配。
* **[^ String]**,	在 [ ]（方括号）和在指定字符串开头的 ^ (插入记号) 指明正则表达式与方括号内的任何字符不匹配。
* **~,!~**,	表示指定变量与正则表达式匹配（代字号）或不匹配（代字号、感叹号）的条件语句。
* **^**,	指定字段或记录的开头。
* **$**,	指定字段或记录的末尾。
* **.**, （句号）	表示除了在空白末尾的终端换行字符以外的任何一个字符。
* **\***（星号）	表示零个或更多的任意字符。
* **\\** (反斜杠)	转义字符

对竖线符号`|`补充两句：

	#匹配的内容是good或bad，是将两个整体来匹配
	good|bad
	#匹配的内容是以d结尾的单词，该单词要么以goo开头要么以ba开头
	(goo|ba)d
	
上面两种竖线匹配结果是一样的，但是匹配的方式不一样，`()`改变了`|`的作用域，有时可能导致匹配错误，需要注意。

