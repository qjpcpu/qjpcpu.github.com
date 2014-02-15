---
layout: post
title: "初识jruby之入门"
date: 2014-02-14 17:24:21 +0800
comments: true
categories: jruby
---

首先，Jruby的官方站点是http://jruby.org/，最详尽的资料都在那里。至于为什么选择JRuby，官方站点上列举了诸如jvm的普及以及性能等等优点，但我想最简单的回答就是，我喜欢用ruby编程，而大多数不再充电的老板还固守着java，对他们来说，相对于ruby，java这个词本身先产生了50%的安全感，所以这可能是比较贴近现实的选择。不过我今天想去倒腾倒腾这个东西，则完全是为了了解ruby的方方面面。

<!-- more -->

###1. 下载安装

首先在官方下载页下载安装最新的jruby，这部分内容还是老老实实去下载页照着做，话说配置开发环境不是每个程序员的必修课吗？不过放心，jruby安装起来很方便的，安装完成后，查看jruby版本，验证是否正确安装：

	C:\>jruby --version
	jruby 1.7.4 (1.9.3p392) 2013-05-16 2390d3b on Java HotSpot(TM) 64-Bit Server VM 1.6.0_38-b05 [Windows 7-amd64]

###2. 在jruby中使用rake,gem等

在jruby下使用这些命令需要前缀一个jruby -S命令，如：

	jruby -S gem list --local
	jruby -S gem install rails mongrel jdbc-mysql activerecord-jdbcmysql-adapter
	jruby -S rails new blog 
	cd blog
	jruby -S rake -T
	jruby -S rake db:create
	jruby -S rake db:migrate

另外，jruby的控制台进入命令时jirb而不是irb：

	C:\>jirb
	irb(main):001:0>

###3. 在jruby中调用java类

例如，在C:\DEMO文件夹下有一个java类文件JavaMan.java：

	package example;
	
	public class JavaMan {
  
      public JavaMan() {
      }
      
      public void hello() {
          System.out.println("Hello, I am a Java man!");
      }
      public void hello(String name){
         System.out.println("Hello "+name+", I am a Java man!");
      }
      
	}

然后在命令行中编译该java类文件：

	C:\DEMO>javac JavaMan.java -d .

在C:\DEMO下建立ruby文件demo.rb：

	require 'java'
	java_import "example.JavaMan" #导入java类JavaMan
	j=JavaMan.new
	j.hello
	j.hello "Jason"

在命令行中执行该ruby脚本使用jruby命令：

	C:\DEMO>jruby demo.rb
	Hello, I am a Java man!
	Hello Jason, I am a Java man!

也可以直接在jirb中调试ruby程序：

	C:\DEMO>jirb
	irb(main):001:0> java_import 'example.JavaMan'
	=> [Java::Example::JavaMan]
	irb(main):002:0> JavaMan.new.hello "Jason"
	Hello Jason, I am a Java man!
	=> nil

###4. 在jruby中实现java接口

若有一个java接口类：

	package example;
	public interface JavaDog{
		public void runs();
	}

那么可以在ruby代码中实现该接口：

	require 'java'
	java_import "example.JavaDog" #导入java接口
	
	class FastDog
		include JavaDog
		def runs
			puts "I am running fast!"
		end
	end
	
	FastDog.new.runs

运行结果：

	C:\DEMO>jruby demo.rb
	I am running fast!

###5. 在jruby中调用jar中的类

若在C:\DEMO\some.jar中包含了一个java bean， example.Person，该类包含了四个属性name,age,sex,country，除了country外其他三个属性都有setter和getter，另外该Person bean还有一个方法getProfile()获取简历。

	require 'java'
	require 'some.jar'
	java_import "example.Person"
	
	p=Person.new
	p.name="Jason"
	p.age=10
	p.sex="Male"
	begin
		p.country="China"
	rescue NoMethodError => e
		puts "No country setter in Person bean"
	end
	puts p.getProfile

运行结果：

	C:\DEMO>jruby demo.rb
	No country setter in Person bean
	Name:Jason Sex:Male Age:10
