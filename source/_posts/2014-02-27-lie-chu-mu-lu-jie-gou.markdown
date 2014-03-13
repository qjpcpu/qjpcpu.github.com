---
layout: post
title: "列出目录结构"
date: 2014-02-27 20:52:50 +0800
comments: true
categories: shell
---

### 最简单美观的方法tree

tree命令是专门用来罗列目录结构的，输出树形结果，很漂亮。

```bash
$ tree demo
demo
├── Gemfile
├── boot.rb
├── collectors
├── config
│   └── mail_config.rb
├── controllers
├── db
│   ├── connection.rb
│   ├── database.yml
│   └── migrate
├── helpers
├── models
├── rakefile
└── views

8 directories, 6 files
```
<!--more-->

### 折衷的方法find

如果没有权限在机器上安装tree命令，find命令也是一种折衷的选择。

```bash
$ find demo -type f -o -type d
demo
demo/boot.rb
demo/collectors
demo/config
demo/config/.gitkeep
demo/config/mail_config.rb
demo/controllers
demo/db
demo/db/connection.rb
demo/db/database.yml
demo/db/migrate
demo/db/migrate/.gitkeep
demo/Gemfile
demo/helpers
demo/helpers/.gitkeep
demo/models
demo/rakefile
demo/views
```

虽然没有tree命令那么直观，但却有另一个好处，便于使用管道进一步操作。

### 仅仅是一种选择ls

ls命令也可以罗列出目录结构，但这个仅供娱乐了。

```bash
$ ls -R demo
Gemfile		collectors	controllers	helpers		rakefile
boot.rb		config		db		models		views

demo/collectors:

demo/config:
mail_config.rb

demo/controllers:

demo/db:
connection.rb	database.yml	migrate

demo/db/migrate:

demo/helpers:

demo/models:

demo/views:
```

### 利用shell自己来实现

在无法安装软件的情况下，自己写一个tree命令吧，至少基本的bash是可以用的。

```bash tree.sh
#!/bin/bash

n_char(){
	ch="$1"
	cnt=$2
	for((i=0;i<$cnt;i++));do
		string="${ch}____$string"
	done
	echo $string
}

dive_into(){
	ls -1a "$1" | while read f
	do
		if [ "$f" == "." ] || [ "$f" == ".." ];then
			continue
		fi
		if [ "$4" = "0" ] && [ "${f:0:1}" = "." ];then
			continue
		fi
		pre=$(n_char '|' $2)
		line="${pre//_/ }|-- ${f}"
		[[ -L "$1/$f" ]] && line="${line} -> `readlink "$1/$f"`"
		if [ "$5" = "1" ];then
			s=`du -sh "$1/$f"|awk '{print $1}'`
			line="${line} [$s]"
		fi
		echo "$line"
		if [ -d "$1/${f}" ] && [ ! -L "$1/$f" ] && [ $(($2+1)) -lt $3 ];then
			dive_into "$1/$f" $(($2+1)) $3 $4 $5
		fi
	done
}
while getopts "d:l:ahs" args
do
	case $args in
	l) level=$OPTARG
	;;
	d) dir="$OPTARG"
	;;
	a) all=1
	;;
	s) size=1
	;;
	h) echo "Must specify directoy with -d"
	   echo "Usage: tree.sh -d directory "
	   echo "-l maxdepth, the tree depth"
	   echo "-s, print file size"
	   echo "-a, print with hidden files"
	   exit 1
	;;
	?) echo "No such argument"
	   exit 1
	;;
	esac
done

[[ -z "$dir" ]] && {
	echo "Must specify directory with -d"
	exit 1
}
[[ -z "$level" ]] && level=100
[[ -z "$all" ]] && all=0
[[ -z "$size" ]] && size=0

echo "$dir"
dive_into "$dir"  0 $level $all $size
```

试试看好用不：

```bash
tree.sh -h
Must specify directoy with -d
Usage: tree.sh -d directory
-l maxdepth, the tree depth
-s, print file size
-a, print with hidden files

tree.sh -d .
.
|-- dir
|    |-- file
|    |-- g.css
|    |-- sub
|    |    |-- sfile
|-- g -> dir/g.css
|-- ldir -> dir/
|-- m.html -> o.html
|-- o.html
|-- s.html
|-- tree.sh
```
