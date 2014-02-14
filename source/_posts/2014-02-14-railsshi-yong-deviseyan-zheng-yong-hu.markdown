---
layout: post
title: "rails使用devise验证用户"
date: 2014-02-14 22:46:34 +0800
comments: true
categories: rails
---

### 安装配置devise

在gemfile中添加一行：

	gem 'devise'
	
执行bundle install后，需要安装devise到工程：

	rails generate devise:install

创建验证用户model，通常用user，也可以使用其他名称：

	rails generate devise user
	rake db:migrate

查看models文件夹下devise创建了user.rb文件：

![image](../images/20130618141054171.png)

devise方法来自Devise gem，其中默认启用了database_authenticatable,registerable等模块，注释部分列出了其他模块默认未启用，根据devise文档按需要使能。

attr_accessible定义的属性可以被create, update_attributes使用，未在这里定义的属性会引发这两个方法的 mass-assignment异常。

查看路由文件 routes.rb，devise gem在创建model时在路由文件中添加了： `devise_for :users`

执行rake routes可以看到devise创建的url：

![image](../images/20130618141818062.png)

注意devise gem提供的账户注销和用户退出登陆都是默认使用的DELETE方法，该url设计常导致编码出错，但它确是遵循了RESTful规范，留意下即可。

在需要的页面上添加注册、登陆的代码（我添加在application.html.erb中yield语句上方）：

![image](../images/20130618142335171.png)

rails server启动服务器，即可查看注册登陆页面：

![image](../images/20130618142534640.png)

### devise提供的常用method

	* authenticate_user!，验证用户是否登陆，常用于before_filter: `before_filter :authenticate_user!`. 另，如果你创建的devise model叫admin，那么该方法就是authenticate_admin!，以下方法同理。这又是ruby玩的一个小把戏了。
	* user_signed_in?，当前是否有登陆用户
	* current_user， 获取当前登陆用户
	* user_session, 用户session，类似于session，也是一个hash表，可以用来保存用户特有的数据
	* after_sign_in_path_for和after_sign_out_path_for方法指定用户登入/登出后的跳转url.


### 自定义views

devise gem提供了足够功能的用户验证，但是由上图可见，其自带的view未免太过简单。如果需要自定义视图，就需要将devise默认的view拷贝到rails工程：
	
	rails generate devise:views
	
![image](../images/20130618145150890.png)

该命令将devise的views复制到工程目录app/views下，分类为多个文件夹。修改需要的view模板就能够改变对应界面。

### 自定义controller

* 如果需要自定义controller，如Devise::SessionController：

		class Admins::SessionsController < Devise::SessionsController
		end
		
* 在路由文件routes.rb中更新配置，告诉devise使用新的controller
 
		devise_for :users, :controllers => { :sessions => "admins/sessions" }

* 更新了controller后，在app/views/devise/sessions下的views不会再被使用，所以，还需要将这部分views复制到app/views/admins/sessions下，或者在该目录下建立新的views。

### 邮件确认

如果需要更安全一点的注册验证，可以使用邮件确认方式。

首先，修改user.rb文件，启用devise的confirmable模块：

![image](../images/20130618153122203.png)

在数据表users中新加字段：

	rails g migration add_confirmable_fields_to_users

![image](../images/20130618153359328.png)

新用户是以邮件的方式确认，所以，需要更改rails的环境配置。rails的环境配置位于config/environments/xxx.rb文件，xx代表develepment/test/production，三个文件的配置选项都十分类似，下面以production环境为例，打开config/environments/production.rb，在最后的end前添加：

![image](../images/20130618154736625.png)

配置邮件帐户，在production时rails建议使用邮件服务如Mandrill，这里为了简单，使用gmail帐户示例。

在改文件中继续添加smtp配置，新添加的内容最终如下：

![image](../images/20130618161158218.png)

最后，修改devise.rb文件

	config.mailer_sender = "replyme@126.com" 

现在，当新用户new@test.com注册后，它会收到一封确认邮件，邮件from: your_gmail_username@gmail.com, to: new@test.com, reply_to: replyme@126.com，邮件包含一个链接，指向用户激活地址。用户点击该链接激活帐户后才能登陆网站。