---
layout: post
title: "在一组方法中共享变量"
date: 2014-02-14 23:46:19 +0800
comments: true
categories: ruby
---

	lambda{
		shared=10
		Kernel.send :define_method, :counter do
			shared+=1
		end
		Kernel.send :define_method, :show do
			shared
		end
	}.call
	
	show #=>10
	3.times{counter}
	show #=>13
	

<!-- more -->
