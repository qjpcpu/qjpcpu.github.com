---
layout: post
title: "rails使用bootstrap及bootswatch"
date: 2014-02-14 15:14:34 +0800
comments: true
categories: rails
---

### 1.简介

Twitter-bootstrap是一个功能强大的前端web框架，使用它可以快速地开发出漂亮的web UI。而thomas-mcdonald/bootstrap-sass是rails sass版本的bootstrap。其他类似的gem还有jlong/sass-twitter-bootstrap，metaskills/less-rails-bootstrap，seyhunak/twitter-bootstrap-rails，前一个也是sass版本，后两个是less版本的。另外，jasny-twitter-bootstrap是bootstrap的一个很好的拓展，添加了文件上传等漂亮的插件。

而Bootswatch是基于bootstrap的主题资源站，提供了很多收费和免费的主题，利用这些现成的主题能够在bootstrap的基础上更进一步加快网站开发，制作出精美的页面。

### 2.安装twitter-bootstrap

这里推荐使用tomas-macdonald/bootstrap-sass。首先在gemfile中添加：

	gem 'sass-rails', '~> 3.2'
	gem 'bootstrap-sass', '~> 2.3.2.0'

然后执行bundle install安装需要的gem。
在app/assets/javascripts/application.js文件中添加需要的javascript引用：

	//= require jquery
	//= require jquery_ujs
	//= require bootstrap
	//= require_tree .

将app/assets/stylesheets/application.css重命名为app/assets/stylesheets/application.css.scss。

现在可以调整app/views/layouts/application.html.erb模板布局，然后就可以浏览twitter-bootstrap网站按照example美化自己的rails站点了。

### 3.安装bootswatch主题

如果还想利用bootswatch的主题，就可以使用maxim/bootswatch-rails来方便地继承bootswatch的免费主题。

在gemfile中添加：

	gem 'bootswatch-rails'

然后执行bundle install安装该gem。在application.css.scss文件中require语句后添加：

	// 示例：使用bootswatch免费主题： 'Cerulean' bootswatch
	// 首先导入变量
	@import "bootswatch/cerulean/variables";
	
	// 导入bootstrap
	@import "bootstrap";
	
	// 修改bootstrapbody边距
	body { padding-top: 60px; }
	
	// 导入bootstrap Responsive styles
	@import "bootstrap-responsive";
	
	// 最后导入需要的bootswatch主题
	@import "bootswatch/cerulean/bootswatch";
	
	// 你还可以在base.css.scss文件中添加更多自定义设置
	@import "base";

你需要在application.css.scss文件相同目录下创建base.css.scss文件，如果需要就在其中添加更多自定义选择。

### 4.Bug fix

在rails中使用bootswatch可能导致某些css设置失效，通常的可能就是在/app/assets/stylesheets目录下，某些css设置覆盖了bootswatch的配置。比如，按照上述方法配置的bootswatch主题就有可能无法显示主题背景色（body背景色始终是白色）。而rails自动产生的scaffolds.css.sass文件中就覆盖了body的背景色配置，故而导致该bug。所以删除scaffolds.css.scss中除.field_with_errors  和 #error_explanation 其余内容即可。

另外，使用一些其他的rails gem也可能无法使用bootswatch的主题，比如jQuery-modal-rails，它是一个简单的模态对话框gem，但它的对话框就是白底，无法使用bootswatch的主题配置，此时手工配置一下即可，如在需要的页面的.css.sass文件中配置.modal {background-color: green;}，就可以显示绿色的模态对话框。
