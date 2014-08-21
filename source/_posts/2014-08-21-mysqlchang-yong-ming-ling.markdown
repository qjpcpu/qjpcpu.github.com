---
layout: post
title: "mysql常用命令"
date: 2014-08-21 11:05:13 +0800
comments: true
categories: mysql
---

### 1.远程链接mysql

```mysql -h主机地址 -u用户名 －p用户密码 －P 端口号grant all on *.* to ‘用户名’@’主机地址’ identified by ‘密码’grant select on 数据库.* to 用户名@登录主机 identified by \"密码\"```
### 2.修改密码
```mysqladmin -u用户名 -p旧密码 password 新密码
```### 3.显示数据库列表。

```show databases
```### 4.显示库中的数据表
```show tables
```### 5.显示数据表的结构
```describe 表名
```
<!--more-->### 6.建库
```create database 库名
```### 7.建表
```create table 表名 (字段设定列表)CREATE TABLE MYTABLE (name VARCHAR(20), sex CHAR(1))
```### 8.删库和删表
```drop database 库名drop table 表名
```### 9.将表中记录清空
```delete from 表名truncate table 表名
```### 10.显示表中的记录
```select * from 表名select * from 表名
```### 11.插入表
```Insert into 表名 values（字段各值）
```### 12.更新表
```Update 表名 set 字段 = 值 where 
```### 13.导入
```数据传入命令 load data local infile "文件名" into table 表名Source sql文件./mysqlimport -u root -p123456 < sql文件
```### 14.导出
```Select * from 表名 into outfile ‘文件名’./mysqldump –opt –database 库名 > sql文件./mysqldump –opt 库名 表名 > sql文件
```### 15.改名
```Alter table 表名 rename 新表名Alter database 库名 rename 新库名
```### 16.查看服务器运行状态
```show status```该命令将显示出一长列状态变量及其对应的值，其中包括：被中止访问的用户数量，被中止的连接数量，尝试连接的次数，并发连接数量最大值，以及其他许多有用的信息。
### 17.显示一个用户的权限，显示结果类似于grant 命令
```show grants for user_name
```### 18.显示表的索引
```show index from table_name
```### 19.显示一些系统特定资源的信息，例如，正在运行的线程数量 ```show status
```### 20.显示系统变量的名称和值
```show variables
```### 21.显示系统中正在运行的所有进程，也就是当前正在执行的查询。大多数用户可以查看
```show processlist```
他们自己的进程，但是如果他们拥有process权限，就可以查看所有人的进程，包括密码
### 22.显示当前使用或者指定的database中的每个表的信息。信息包括表类型和表的最新更新时间
```show table status
```### 23.显示服务器所支持的不同权限
```show privileges```
### 24.显示create database 语句是否能够创建指定的数据库
```show create database database_name```
### 25.显示create database 语句是否能够创建指定的数据库
```show create table table_name
```### 26.显示innoDB存储引擎的状态
```show innodb status
```### 27.显示BDB存储引擎的日志
```show logs
```### 28.显示最后一个执行的语句所产生的错误、警告和通知
```show warnings
```### 29.只显示最后一个执行语句所产生的错误
```show errors```