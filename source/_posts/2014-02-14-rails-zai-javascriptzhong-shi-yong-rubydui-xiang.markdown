---
layout: post
title: "rails 在javascript中使用ruby对象"
date: 2014-02-14 23:40:15 +0800
comments: true
categories: rails
---

### 1.在javascript中使用ruby简单对象

如，需要将ruby对象转换成javascript的简单变量：

	<%= javascript_tag do %>
	  url = '<%= j products_url %>';
	<% end %>

此时的<%=  %>是由引号包裹的。rails的j方法是为了正确地转义ruby对象从而嵌入javascript中。

### 2.在javascript中使用ruby复杂对象

公共桥梁显然是json，但要正确地转义json就需要raw方法：

	<%= javascript_tag do %>
	  products = <%= raw Product.limit(10).to_json %>
	<% end %>

此时<%= %>无引号包裹。

### 3.Gon gem

如果有大量的ruby对象需要在javascript中使用，这种方法就不好了。Gon就是为了解决这个问题。

首先在gemfile中添加gon：

	gem 'gon'

然后在/app/views/layouts/application.html.erb文件中包含gon：

	<head>
	  <title>Store</title>
	  <%= include_gon %>
	  <%= stylesheet_link_tag    "application", media: "all" %>
	  <%= javascript_include_tag "application" %>
	  <%= csrf_meta_tag %>
	</head>

然后在controller中就可以以这种形式为javascript对象赋值：

	gon.variable_name = variable_value
	# or new syntax
	gon.push({
	  :user_id => 1,
	  :user_role => "admin"
	})
	gon.push(any_object) # any_object with respond_to? :each_pair

例如：

	class ProductsController < ApplicationController
		def index
			gon.products = Product.limit(10)
		end
	end
	
在js中获取变量的方法：

	gon.variable_name

即：

	go.products

### 参考文献

* [gon](https://github.com/gazay/gon)
* [Passing data to javascript](http://railscasts.com/episodes/324-passing-data-to-javascript?view=asciicast)