---
layout: post
title: "rails Eagerloading"
date: 2014-02-14 23:05:33 +0800
comments: true
categories: rails
---

若存在如下Post model：

	class Post < ActiveRecord::Base
		belongs_to :author
		has_many :comments
	end

使用下面的循环加载数据时产生了N+1查询问题：


	Post.all.each do |post|
	  puts "Post:            " + post.title
	  puts "Written by:      " + post.author.name
	  puts "Last comment on: " + post.comments.first.created_on
	end

首先，解决author获取问题：

	Post.includes(:author).each do |post|

然后解决comments加载：

	Post.includes(:author, :comments).each do |post|

带条件的eager loading：

	Post.includes([:author, :comments]).where(['comments.approved = ?', true]).all

多态关系的eager laoding

	class Address < ActiveRecord::Base
		belongs_to :addressable, :polymorphic=>true
	end
	Address.includes(:addressable)