---
layout: post
title: "初识jruby之安装配置jrubyonrails"
date: 2014-02-14 23:49:23 +0800
comments: true
categories: jruby
---

### 1. prerequesite

假设你已经安装好了jruby，并且使用的jdk最好是1.7。

### 2. 安装rails

安装rails4.0.0：

	C:\>jruby -S gem install rails -V

查看安装的rails版本：

	C:\>jruby -S rails -v
	Rails 4.0.0

### 3. 新建一个rails Apps

	C:\>jruby -S rails new demo

并且取消bundle install，因为使用默认安装的ActiveRecord-JDBC-adapter的master分支版本目前，会导致执行rake db:migrate命令时发生wrong number of arguments calling exec_insert (5 for 3) error错误，所以，修改gemfile使用它的1.3.0.beta2版本（这个步骤是现在的权宜之计，以后肯定不必这么麻烦了。后注：此问题目前已修复)：

如果使用的是sqlite数据库，则将：

	gem 'activerecord-jdbcsqlite3-adapter'

改为：

	gem 'activerecord-jdbcsqlite3-adapter', '1.3.0.beta2'

如果使用的mysql数据库，则将：

	gem 'activerecord-jdbcmysql-adapter'

改为：

	gem 'activerecord-jdbcmysql-adapter','1.3.0.beta2'
 
然后再进行 jruby -S bundle install 安装gem。

如果使用sqlite数据库，默认配置即可，如果使用mysql数据库，则修改database.yml，以development
环境为例，这里的username，password，host，port按照具体情况进行具体配置：

	development:
	  adapter: mysql
	  encoding: utf8
	  reconnect: false
	  database: demo_development
	  username: user
	  password: user_password
	  host: localhost
	  port: 3306

最后，启动rails app：

	C:\DEMO>jruby -S rails s

然而此时又出错了：

	OpenSSL::Cipher::CipherError: Illegal key size: possibly you need to install Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files for your JRE

要求安装JCE，到Oracle 官网上下载一个UnlimitedJCEPolicyJDK7.zip文件，解压缩后包含两个jar文件：local_policy.jar和US_export_policy.jar。将这两个文件替换$JAVA_HOME/jre/lib/security目录下两个同名文件，如，在我的电脑是就是替换C:\Program Files\Java\jdk1.7.0_25\jre\lib\security目录下两个文件。替换后，重启电脑。

此时，再jruby -S rails s启动app则可以正确运行了。

### 4. 配置java类路径

如果需要在rails中使用java外部类，则需要配置一下$CLASSPATH，首先，假设我们将需要的java类都放在rails_root/lib/java文件夹下。那么就在environment.rb文件中require File.expand_path('../
application', \__FILE__)后添加代码：

	require 'java'
	$CLASSPATH << File.join(Rails.root, 'lib','java')

这样，如果在该目录下有一个编译好的java类example.MyClass在rails中就可以像这样使用该类：

	mc=Java::example.MyClass.new

如果还使用了外部jar，则还要添加引用jar的代码，同样在environment.rb文件中添加：

	Dir.glob(File.join(Rails.root, 'lib','java',"**","*.jar")).each do |jar| 
		$CLASSPATH << jar
	end

所以最终environment.rb文件看起来是这样的：

> environment.rb

	# Load the rails application
	require File.expand_path('../application',__FILE__)
	requrie 'java'
	$CLASSPATH<<File.join(Rails.root,'lib','java')
	Dir.glob(File.join(Rails.root,'lib','java','**','*.jar)).each do |jar|
		$CLASSPATH << jar
	end
	
	Demo::Application.initialize!

