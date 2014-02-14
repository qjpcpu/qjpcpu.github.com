---
layout: post
title: "rails为paperclip上传文件添加访问控制"
date: 2014-02-14 15:21:11 +0800
comments: true
categories: rails
---

###0 前言

由paperclip上传的文件默认是放在rails项目的public目录下的，也就是说，只要能得到该文件的URL，就可以直接访问/下载该文件，如果要对该文件添加访问控制，就需要更改paperclip的默认上传位置。

###1 更改paperclip默认的上传位置

若有一个story类，每个story有一个封面cover，该cover是一张图片，就可以这样更改model定义：

	class Story < ActiveRecord::Base
	  has_attached_file :cover,
	  :styles=>{:small=>"32x32"}, 
	  :path => ":rails_root/paperclip/:class/:attachment/:id/:style/:filename",
	  :url => "/paperclip/:class/:attachment/:id/:style/:filename"
	end

要同时修改path和url，url是相对于rails工程而言，被rails app用来获取图片渲染页面；而path是相对于rails app服务器而言，在整个宿主文件系统中的路径。必须同时修改path和url。

这里，将保存paperclip的上传文件的目录设置为rails工程根目录下的paperclip目录。

###2 添加controller

在routes.rb中添加路由：

	get "/paperclip/:class/:attachment/:id/:style/:filename",to:"assets#show"

添加assets_controller.rb文件：

	class AssetsController < ApplicationController
	  def show
	    cls=params[:class].singularize.capitalize.constantize
	    asset=cls.find params[:id]
	    send_file asset.send(params[:attachment].singularize).path(params[:style])
	  end
	end

在提交的参数中params[:class]是复数形式，而通常类定义都是单数如Story，params[:attachment]是也复数形式而类定义中cover为单数，所以都要将他们变成单数，如果类中定义的attachment是复数形式，那么这里attachment就不必转换为单数，否则会引发NoMethod异常。

现在，所有的paperclip资源都由AssetsController控制，所以在其中添加诸如身份登录验证等before_filter就很方便了。在加入身份验证后，即便用户得到该cover的URL，在未登录的情况下，也无法直接访问该图片了。
