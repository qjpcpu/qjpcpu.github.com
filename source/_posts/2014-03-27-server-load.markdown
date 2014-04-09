---
layout: post
title: "server load"
date: 2014-03-27 09:39:14 +0800
comments: true
categories: linux
---

### 先看几个处理器

```bash
grep -c 'model name' /proc/cpuinfo
```
比如结果是4

### top查看系统整体情况

执行`top`命令查看系统负载情况：
1. 关注`load average`系统负载的当前，5分钟前，15分钟前负载，最好小于cpu个数
2. 第二行显示系统进程概况
3. 第四行us用户占用cpu，sy系统占用cpu，ni，id空闲比例，wa io等待，hi，si swap交换
4. 最后是内存情况和交换分区

### iostat检查io情况

`iostat -x`，需要关注await即io等待时间，单位ms，一般要小于5ms； %util是io处理时间除以总时间，代表io繁忙度，大于70%需要注意。

### vmstat查看系统概况

	procs -----------memory---------- ---swap-- -----io---- --system-- ----cpu----
	 r  b   swpd   free   buff  cache   si   so    bi    bo   in    cs us sy id wa
	 1  0 409548 3317764  56864 39709176    0    0    12    29    0     0  4  1 96  0
 
 主要看r和b，代表当前执行进程和阻塞进程，当r长期大于cpu个数需要注意，还有阻塞进程过多也需要注意
 
 
### ps和pstree查看进程

查看线程个数可以用`cat /proc/PID/status|grep Threads`，另外对于ps，可以这样查看具体线程

```bash
ps -mp PID -o THREAD,tid,time
```
如：

	USER     %CPU PRI SCNT WCHAN  USER SYSTEM   TID     TIME
	work      1.8   -    - -         -      -     - 15:08:33
	work      0.0  14    - -         -      - 11750 00:00:00
	work      0.0  23    - -         -      - 11751 00:00:14
	work      0.0  23    - -         -      - 11760 00:03:36

关注%CPU占用cpu情况，TID是线程id，TIME是占用cpu的时间长。

对于java进程可以用来调试程序：

```bash
# tid 转为16进制
printf "%x\n" tid
jstack PID | grep tid -A 50
```
### 怎么启动这个程序的

```bash
pmap PID
```