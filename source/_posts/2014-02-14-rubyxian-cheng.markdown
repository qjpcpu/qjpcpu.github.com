---
layout: post
title: "ruby线程"
date: 2014-02-14 22:35:53 +0800
comments: true
categories: ruby
---

### 1. 创建线程

		Thread.new do
			3.times do 
				sleep 3
				puts "Thread #{Thread.current.object_id} running..."
			end
		end

ruby使用在Thread.new创建线程，线程创建后立即返回，线程也同时开始执行。ruby线程可以在创建块中使用外部变量，也可以使用本地变量，值变量在线程内部保存的是本地副本，而引用变量保存的是一个本地引用。

	class Book
		attr_accessor :name
	end
	num = 0
	count = 0
	book = Book.new
	book.name = 'ybur'
	puts "main Thread=#{num} count=#{count} book=#{book.name}"
	
	t.Thread.new(num,book) do |n,b|
		n+=1
		count+=1
		b.name.reverse!
		puts "new Thread:num=#{n} count=#{count} book=#{b.name}"
	end
	t.join
	puts "main Thread:num=#{num} count=#{count} book=#{book.name}"
	#=>main Thread:num=0 count=0 book=ybur
	#=>new Thread:num=1 count=1 book=ruby
	#=>main Thread:num=0 count=1 book=ruby

<!-- more -->

新线程中保存num的副本，在线程中更改num并不影响外部num值，而新线程对book的修改会直接影响外部book，在新线程中也可打破作用域直接访问外部count并作出修改。

常用方法

	Thread.current #获取当前线程
	Thread.list #所有线程列表
	Thread#status #线程状态
	Thread#alive?
	Thread#stop?
	Thread#join

线程可以将某些信息放在自身的hash表中，让别的线程访问。使用Thread#value（阻塞方法）访问线程执行最后一行代码的结果：

	t=Thread.new(1,10) do |a,b|
		sleep 3
		Thread.current['plus_result']=a+b
		"thread result:#{a+b}"
	end
	t.join
	puts "1+10=#{t['plus_result']}"
	puts "#{t.value}"
	#=> 1+10=11
	#=> thread result:11

### 2. Mutex

来自ruby-doc的例子

	require 'thread'
	mutex=Mutex.new
	count1=count2=0
	difference=0
	counter=Thread.new do
		loop do
			mutex.synchronize do
				count1+=1
				count2+=1
			end
		end
	end
	spy=Thread.new do
		loop do
			mutex.synchronize do
				difference+=(count1-count2).abs
			end
		end
	end
	sleep 1
	mutex.lock
	#=> count1 >> 21192
	#=> count2 >> 21192
	#=> difference >>0

### 3. Condition Variables

来自ruby-doc

	require 'thread'
	mutext=Mutex.new
	cv=ConditionVariable.new
	a=Thread.new {
		mutex.synchronize {
			puts "A:I have critical section, but will wait for cv"
			cv.wait mutex
			puts "A:I have critical section again! I rule!"
		}
	}
	puts "(Later, back at the ranch...)"
	b=Thread.new {
		mutex.synchronize {
			puts "B: Now I am critical, but am done with cv"
			cv.signal
			puts "B: I am still critical, finishing up"
		}
	}
	a.join
	b.join
	
	produces:
	A:I have critical section, but will wait for cv(Later, back at the ranch...)
	B: Now I am critical,but am done with cv
	B:I am still critical, finishing up
	A: I have critical section again! I Rule!

在进入临界区并在cv上等待时，会释放该互斥锁mutex，从而才能让别的线程进入临界区，不至于发生死锁。

### 4. Queue

ruby的Queue和java的BlockingQueue十分类似。当Queue为空时，执行pop操作会导致线程挂起等待。

	require 'thread'
	queue=Queue.new
	producer=Thread.new do 
		5.times do |i|
			sleep 4
			queue << i # operator << is alias of push
			puts "#{i} produced"
		end
	end
	consumer=Thread.new do 
		5.times do |i|
			value=queue.pop
			sleep 2
			puts "consumed #{value}"
		end
	end


ruby还提供了一个SizedQueue，当达到队列最大长度后，执行push操作时也会导致线程挂起。