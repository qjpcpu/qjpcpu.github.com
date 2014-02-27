---
layout: post
title: "find命令"
date: 2014-02-27 20:10:37 +0800
comments: true
categories: shell
---

### find的基本语法

```bash
find PATH OPTIONS [-exec COMMANDD {} \;]
```

`find`命令可以使用多个OPTION，不同OPTION之间默认是`and`关系，除了`and`关系还有`not`和`or`关系，如：

```bash
find / -name 'n1' -type f  #查找/目录下名称为n1且为普通文件的文件
find / -name 'n1' -o -name 'n2' #查找名称为n1或n2的文件
find / ! -name 'n1'  # 查找名称不为n1的文件
```

当使用的OPTION很多时，可以将OPTIONS括起来增加可读性，注意括号需要用`\`来转义，同时`\(`和`\)`两边都需要有空格：

```bash
find / \( -name 'n1' -o -name 'n2' \)
```
<!--more-->

### find命令常用的OPTION

* -name  按名称查找，支持通配符*,?,[]
* -user  按用户名查找
* -empty  查找空文件(目录)
* -perm  查找对应权限的文件，权限表示的三位数字形式如777
* -type 按类型查找，类型可为`b`块设备，`c`字符设备，`p`管道，`f`普通文件，`l`链接文件，`s`socket文件
* -print  打印结果
* -regex 按正则表达式查找，注意该正则匹配属于完全匹配，即如果要查找`dir`目录下的文件`file_23`应该用正则表达式`.*file_[0-9]+`，用`file_[0-9]+`是匹配不到的，`find dir -regex '.*file_[0-9]+`是用完整结果即`dir/file_23`来做和`-regex`完全匹配的
* -maxdepth n  find的最大目录层级查找深度，最小为1
* -mindepth n find的最小目录查找深度

按时间查找的参数：

* -amin n  查找n分钟以前被访问（access）的文件
* -atime n  查找n天前被访问的文件
* -cmin n  查找n分钟前文件元信息被修改（change）的文件
* -ctime n  查找n天前文件元信息被修改过的文件
* -mmin n  查找n分钟前内容被修改的文件
* -mtime n 查找n天前内容被修改的文件

### exec

find命令最后的exec表示对找到的文件执行什么命令，其中`{}`代表找到的文件，注意`{}`和`\;`间有空格。

