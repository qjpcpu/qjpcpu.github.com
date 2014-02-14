---
layout: post
title: "ruby线程"
date: 2014-02-14 22:35:53 +0800
comments: true
categories: ruby
---

1. 创建线程

![image](../images/20130615125249265.png)

ruby使用在Thread.new创建线程，线程创建后立即返回，线程也同时开始执行。ruby线程可以在创建块中使用外部变量，也可以使用本地变量，值变量在线程内部保存的是本地副本，而引用变量保存的是一个本地引用。

![image](../images/20130615132410906.png)

新线程中保存num的副本，在线程中更改num并不影响外部num值，而新线程对book的修改会直接影响外部book，在新线程中也可打破作用域直接访问外部count并作出修改。

常用方法

![image](../images/20130615132410906.png)

线程可以将某些信息放在自身的hash表中，让别的线程访问。使用Thread#value（阻塞方法）访问线程执行最后一行代码的结果：

![image](../images/20130615143555750.png)

2. Mutex

来自ruby-doc的例子

![image](../images/20130615140140578.png)

3. Condition Variables

来自ruby-doc

![image](../images/20130615134503984.png)

在进入临界区并在cv上等待时，会释放该互斥锁mutex，从而才能让别的线程进入临界区，不至于发生死锁。

4. Queue

ruby的Queue和java的BlockingQueue十分类似。当Queue为空时，执行pop操作会导致线程挂起等待。

![image](../images/20130615140140578.png)

ruby还提供了一个SizedQueue，当达到队列最大长度后，执行push操作时也会导致线程挂起。