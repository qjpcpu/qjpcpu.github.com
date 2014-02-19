---
layout: post
title: "sendmail发邮件中文乱码"
date: 2014-02-19 23:23:15 +0800
comments: true
categories: shell
---

如果这是要使用sendmail命令发送的邮件file内容：

	Subject:标题
	TO:to@example.com
	From:from@example
	Content-Type:text/html
	<html>
		<body>
			邮件内容
		</body>
	</html>
	
### 解决内容乱码

内容乱码比较好解决，首先内容先使用utf-8编码，然后在修改邮件的`Content-Type`为：

	Content-Type:text/html;charset=UTF-8
	
### 解决标题乱码

需要利用base64编码标题内容，例如，如果UTF-8编码的字符串`标题`进行base64编码后的内容为`5qCH6aKY`,则邮件标题为：

	Subject:=?UTF-8?B?5qCH6aKY?=
	
即邮件标题`Subject:`后字符串格式为："`=?UTF-8?B?`*base64编码的utf-8字串*`?=`"

### 发送邮件

最后发送文件可以正确显示：

``` bash
cat file | sendmail -t
```
