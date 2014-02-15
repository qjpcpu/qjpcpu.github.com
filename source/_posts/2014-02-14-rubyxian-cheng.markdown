---
layout: post
title: "ruby线程"
date: 2014-02-14 22:35:53 +0800
comments: true
categories: ruby
---

1. 创建线程

![image](http://f.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=c21f71f885d6277fed12323d18036e0d/a08b87d6277f9e2f4216f84b1d30e924b899f356.jpg?referer=033dd984925298225c240cf33d4c&x=.jpg)

ruby使用在Thread.new创建线程，线程创建后立即返回，线程也同时开始执行。ruby线程可以在创建块中使用外部变量，也可以使用本地变量，值变量在线程内部保存的是本地副本，而引用变量保存的是一个本地引用。

![image](http://d.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=6326cf43eb24b899da3c793d5e3d6ca8/1e30e924b899a9010716be751f950a7b0208f556.jpg?referer=9cd4abb80846f21f90236b63334c&x=.jpg)

新线程中保存num的副本，在线程中更改num并不影响外部num值，而新线程对book的修改会直接影响外部book，在新线程中也可打破作用域直接访问外部count并作出修改。

常用方法

![image](http://d.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=6326cf43eb24b899da3c793d5e3d6ca8/1e30e924b899a9010716be751f950a7b0208f556.jpg?referer=9cd4abb80846f21f90236b63334c&x=.jpg)

线程可以将某些信息放在自身的hash表中，让别的线程访问。使用Thread#value（阻塞方法）访问线程执行最后一行代码的结果：

![image](http://e.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=5bdd5f9c74c6a7efbd26a823cdc1de6c/91ef76c6a7efce1b21da3289ad51f3deb58f6584.jpg?referer=1ad267a0ff1f4134b920314ec39a&x=.jpg)

2. Mutex

来自ruby-doc的例子

![image](http://b.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=6cae4a46e7dde711e3d243f397d4bf26/8435e5dde71190efcf0a689ccc1b9d16fcfa6084.jpg?referer=08f9fc89808ba61e86f9fc1fc09a&x=.jpg)

3. Condition Variables

来自ruby-doc

![image](http://f.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=9ae2764b99504fc2a65fb000d5e6962c/b8389b504fc2d56230f92aaee51190ef77c66c84.jpg?referer=d94d4f791bd8bc3e9f1f32facc9a&x=.jpg)

在进入临界区并在cv上等待时，会释放该互斥锁mutex，从而才能让别的线程进入临界区，不至于发生死锁。

4. Queue

ruby的Queue和java的BlockingQueue十分类似。当Queue为空时，执行pop操作会导致线程挂起等待。

![image](http://b.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=6cae4a46e7dde711e3d243f397d4bf26/8435e5dde71190efcf0a689ccc1b9d16fcfa6084.jpg?referer=08f9fc89808ba61e86f9fc1fc09a&x=.jpg)

ruby还提供了一个SizedQueue，当达到队列最大长度后，执行push操作时也会导致线程挂起。