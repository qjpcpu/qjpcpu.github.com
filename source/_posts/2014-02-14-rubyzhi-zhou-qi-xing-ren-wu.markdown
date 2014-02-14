---
layout: post
title: "ruby之周期性任务"
date: 2014-02-14 17:38:41 +0800
comments: true
categories: ruby
---
###1.前言

无论是用ruby做系统管理，还是用rails做web开发，都可能遇到周期性任务，它们按照一定时间周期（1小时，2天......）持续地触发。在ruby中，我认为一次性任务使用sidekiq来完成是非常方便的，而周期性的任务就需要用到whenever，sidetiq，clockwork等等gem了。

###2.whenever

首先，whenever是基于linux的cron服务的，所以，在windows平台上没有直接的方法使用该gem。whenever严格来说应该算一个cron的翻译器，将ruby代码翻译为cron脚本，从而将周期性任务转交给cron实际去完成。对于精通cron的shell程序员来说可能不值一提，但对rubyist却不是。首先，我们可以使用ruby语言来书写任务代码，在ruby层面上控制代码，避免了和一些shell脚本的切换；另外，cron命令很强大，但我总是记不住它的命令参数，为了避免一遍一遍去man它的手册，还是ruby语法比较亲民。

首先，安装whenever：

	$ gem install whenever

然后切换到任务编写文件夹project下，保证该文件夹下有一个config文件夹。如果是在rails项目中建立
whenever任务，则config文件夹已经存在了。

	$ cd /project
	$ wheneverize .

whenverize命令会在config文件夹下创建schedule.rb文件，我们的任务代码需要在该文件中定义。下面的是schedule.rb文件示例：

	every 3.hours do
	  runner "MyModel.some_process"
	  rake "my:rake:task"
	  command "/usr/bin/my_great_command"
	end
	
	every 1.day, :at => '4:30 am' do
	  runner "MyModel.task_to_run_at_four_thirty_in_the_morning"
	end
	
	every :hour do # 常用的简写有： :hour, :day, :month, :year, :reboot
	  runner "SomeModel.ladeeda"
	end
	
	every :sunday, :at => '12pm' do # 你可以使用星期几或周末或工作日： :weekend, :weekday
	  runner "Task.do_something_great"
	end
	
	every '0 0 27-31 * *' do
	  command "echo 'you can use raw cron syntax too'"
	end

	# run this task only on servers with the :app role in Capistrano
	# see Capistrano roles section below
	every :day, :at => '12:20am', :roles => [:app] do
	  rake "app_server:task"
	end

如示例代码，whenever默认定义了三种任务类型：runner, rake, command，我们也可以定义自己的任务，比如，下面的代码定义了脱离rails环境，独立执行ruby代码的类型：

	job_type :ruby, "cd :path && /usr/bin/ruby ':task'.rb"
	
	every :hour do
	  ruby 'have_a_rest'
	end

该示例描述了：每个小时会执行一次当前文件夹下的have_a_rest.rb脚本。
下面看看怎么将任务写入cron服务。

	$ whenever   #不带参数的whenever会显示转换程cron任务的代码，不写入cron任务表
	$ whenever -w #写入cron任务表，开始执行
	$ whenever -c #取消任务

如果要查看cron任务表，也可以使用linux的命令列出所有cron任务：

	$ crontab -l

###3.sidetiq

sidetiq是sidekiq的亲兄弟，如果在rails项目中使用sidekiq来处理后台任务，那么就用sidetiq来交付周期性任务也显得比较自然。

安装sidetiq：

	$ [sudo] gem install sidetiq

定义周期性任务：

	class MyWorker
	  include Sidekiq::Worker
	  include Sidetiq::Schedulable
	
	  recurrence { daily }
	
	  def perform
	    # do stuff ...
	  end
	end

sidetiq和sidekiq一样，依赖于redis消息来处理消息。当rails项目启动后，这些周期性任务会自动加载执行。

###4.clockwork

clockwork和sidetiq一样，也不必依赖于cron，可以适应”跨平台“要求。下面是代码示例(clock.rb)：

	require 'clockwork'
	include Clockwork
	
	handler do |job|
	  puts "Running #{job}"
	end
	
	every(10.seconds, 'frequent.job')
	every(3.minutes, 'less.frequent.job')
	every(1.hour, 'hourly.job')
	
	every(1.day, 'midnight.job', :at => '00:00')

启动任务：

	$ clockwork clock.rb
	Starting clock for 4 events: [ frequent.job less.frequent.job hourly.job midnight.job ]
	Triggering frequent.job

如果要带上rails环境，就在任务文件加入：

	require './config/boot'
	require './config/environment'
