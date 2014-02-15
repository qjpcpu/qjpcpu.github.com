---
layout: post
title: "rails 填充数据库初始数据"
date: 2014-02-14 23:21:46 +0800
comments: true
categories: rails
---

<!-- more -->

利用db/seeds.rb文件将数据库的initial data填入即可，该文件位于rails环境中，可以访问railsApp中任何类和方法。如，填充product表的初始数据：

> seeds.rb

	5.times do |i|
		Product.create(name:"Product ##{i}",description:"A product")
	end

使用rake命令填充数据：

	rake db:seed

或者从头调用所有migration创建空的数据库并自动seed填充数据库：

	rake db:setup
