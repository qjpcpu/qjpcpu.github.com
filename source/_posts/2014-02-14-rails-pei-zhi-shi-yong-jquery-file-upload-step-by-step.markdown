---
layout: post
title: "rails 配置使用jquery-file-upload  step by step"
date: 2014-02-14 23:11:06 +0800
comments: true
categories: rails
---

一步步安装使用jquery-file-upload

### 1.安装Gem

在gemfile中添加jquery-fileupload-rails和paperclip的gem：

	gem "jquery-fileupload-rails"
	gem 'paperclip'

### 2.在app/assets/application.js添加

	//= require jquery-fileupload

### 3.在app/assets/stylesheets/application.css添加

	*= require jquery.fileupload-ui

### 4.创建Picture数据表


	rails g model Picture avatar:attachment
	rake db:migrate

pictures表的avatar属性代表上传的文件对象。

修改picture.rb的内容：

	class Picture < ActiveRecord::Base
		has_attached_file :avatar
		
		include Rails.application.routes.url_helpers
		
		def to_json_picture
			{
				'name'=>read_attribute(:avatar_file_name),
				'size'=>read_attribute(:avatar_file_size),
				'url'=>avatar.url(:original),
				'delete_url'=>picture_path(self),
				'delete_type'=>'DELETE'
			}
		end
	end

在model中，使用类方法has_attached_file指明文件对象是avatar，并且定义了to_json_picture方法，该方法将picture对象转换成一个hash，在jquery-fileupload和server的交互中被转变为json数据。

### 5.创建view

只需要创建一个上传界面index.html.erb，自定义你自己的view时，仅需要将form_for Picture.new和f.file_field :avatar修改为自己model即可，其他内容都可以直接copy-paste。

[file](../images/rails-jquery-attach.txt)

### 6.创建controller

	rails g controller pictures index create destroy

-

	class PicturesController < ApplicationController
	  def index
	    @pictures = Picture.all
	
	    respond_to do |format|
	      format.html # index.html.erb
	      format.json { render json: @pictures.map{|picuture| picuture.to_json_picture } }
	    end
	  end
	
	  # POST /picture
	  # POST /picture.json
	  def create
	    @picture = Picture.new(params[:picture])
	
	    respond_to do |format|
	      if @picture.save
	        format.html {
	          render :json => [@picture.to_json_picture].to_json,
	          :content_type => 'text/html',
	          :layout => false
	        }
	        format.json { render json: {files: [@picture.to_json_picture]}, status: :created, location: @picture }
	      else
	        format.html { render action: "new" }
	        format.json { render json: @picture.errors, status: :unprocessable_entity }
	      end
	    end
	  end
	
	  # DELETE /picture/1
	  # DELETE /picture/1.json
	  def destroy
	    @picture = Picture.find(params[:id])
	    @picture.destroy
	
	    respond_to do |format|
	      format.html { redirect_to picture_url }
	      format.json { head :no_content }
	    end
	  end
	end

### 7.效果图

![image](../images/20130622184225625.jpeg)

这就是最终结果了，如果想要达到jqeury-fileupload Demo中漂亮的结果，如下图，就需要使用Twitter-bootstrap或者自己写写CSS了。

![image](../images/20130622184920031.jpeg)

