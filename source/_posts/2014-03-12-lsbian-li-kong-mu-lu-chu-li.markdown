---
layout: post
title: "ls遍历空目录处理"
date: 2014-03-12 23:18:02 +0800
comments: true
categories: shell
---

先说说原因：`for`循环是利用空格做分隔符，所以可以这样打印句子中的单词：

	centence="Linux is cool"
	for word in $centence;do
		echo $word
	done

有时用ls命令遍历目录会遇到空目录：

```bash
for d in $(ls);do
	echo "$d"
done
```

处理办法是：

```bash
ls -1 | while read d
do
	echo "$d"
done
```
