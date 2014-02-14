---
layout: post
title: "初识jruby之在tomcat上部署jruby-on-rails"
date: 2014-02-14 23:58:44 +0800
comments: true
categories: jruby
---

### 1. prerequesite

假定部署的sever上已经安装好了Java环境和mysql数据库（因为这里我将以mysql为例）。并且，这里为了和前面几篇博文保持一致，还是在windows上进行部署，实际在linux上部署的节奏也差不多了，即便遇到问题，google is ready for you.

### 2. 安装配置Apache Tomcat

首先，在Apache Tomcat网站上下载tomcat压缩包，目前的版本是7.0。下载完成后解压缩，如解压到C:\，解压缩后目录结构如图：

![image](../images/20130731113711703.jpeg)

进入其中bin目录，并以管理员身份运行startup.bat批处理文件启动tomcat，tomcat默认端口为8080，所以，在浏览器中访问http://localhost:8080，如果出现图示页面说明tomcat安装配置正确。

![image](../images/20130731114036640.jpeg)

### 3. 下载安装jruby

安装jruby在前一篇博文讲解较细，这里不再赘述。

安装必要的JDBC。

	jruby -S gem install activerecord-jdbcmysql-adapter -v 1.3.0.beta2

如果要将jruby on rails工程打包为war发布到tomcat上，就必须要用到warbler Gem：

	jruby -S gem install warbler

### 4. 打包jruby on rails工程

首先确认database.yml文件production环境配置正确：

	production:
	  adapter: mysql
	  encoding: utf8
	  reconnect: false
	  database: demo_production
	  username: user
	  password: password
	  host: localhost
	  port: 3306

配置正确的production数据库，及其用户密码。

在数据库中创建production数据库demo_production，并且赋予用户user对该数据库的完全权限。

然后开始打包工程，在rails app根目录下执行：

	jruby -S warble

该命令会在工程根目录下生成一个war文件，如demo.war，该war会将必要的gem打包进去，使得我们能够像普通java工程war文件那样部署到tomcat中。

### 5. 部署war

将该war复制到tomcat的webapps目录下，等待大约几秒钟，tomcat会自动释放文件完成部署。

最后一步，进入tomcat释放的文件夹demo中，生成数据库schema：

	C:\apache-tomcat-7.0.35\webapps\demo>jruby -S rake db:migrate RAILS_ENV="production"

现在可以访问http://localhost:8080/demo，可以看到rails app的首页了。