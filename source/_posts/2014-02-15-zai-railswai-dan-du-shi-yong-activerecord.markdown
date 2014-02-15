---
layout: post
title: "在rails外单独使用ActiveRecord"
date: 2014-02-15 00:20:50 +0800
comments: true
categories: ruby
---

### 单独使用ActiveRecord

需要在应用根目录demo/下的app.rb文件中写入：

	require 'active_record'  
	require 'sqlite3'  
	  
	ActiveRecord::Base.establish_connection(  
	    :adapter=>'sqlite3',  
	    :database=>'data.sqlite3',  
	    :pool=>5,  
	    :timeout=>5000  
	    )  
	  
	class CreateUsers < ActiveRecord::Migration  
	  def change  
	    create_table :users do |t|  
	      t.string :name  
	      t.integer :age  
	    end 
	  end  
	end  
	
	CreateUsers.new.change
	  
	class User < ActiveRecord::Base  
	end  
	
	User.create name:"Jack",age:12

首先，使用ActiveRecord::Base.establish_connection建立连接，然后定义数据表迁移，再使迁移生效建立数据表，最后就可以像在rails中一样定义model，然后正常使用ActiveRecord了。

代码可以正常工作了，但可以做的工作还有很多，因为这段代码实在是不美观。

### 像样的结构

大杂烩式的代码文件总是不美的，上面代码中包含了数据库连接，表创建，model定义和实际的应用代码四部分，这么多功能各异的部件还是分开好。首先创建demo/db目录，在这个目录下放置所有数据库连接的定义；创建demo/models目录，在下面放置model定义文件。demo/app.rb文件位置不变。

### model定义

model定义文件demo/user.rb的内容就是将上面的user类定义复制过来即可。

	class User < ActiveRecord::Base
	end

### ActiveRecord配置

新建demo/db/connection.rb文件，该文件里设置数据库连接：

	require 'active_record'
	require 'yaml'
	
	dbconfig = YAML::load(File.open('db/database.yml'))
	ActiveRecord::Base.establish_connection(dbconfig)

这里模仿rails使用了yaml来配置连接，该文件也在demo/db目录下，内容为：

	adapter: sqlite3
	database: data.sqlite3
	pool: 5
	timeout: 5000

现在的demo/app.rb清爽多了：

	require File.expand_path('../db/connection',__FILE__)
	Dir[File.expand_path('../models',__FILE__)+'/*.rb'].each{|f| require f }
	
	User.create name:"Jack",age:12

### 数据表迁移

现在还有一个问题，我也想像rails中那样利用rake来迁移数据表定义。参考我前一篇博客Rake就可以轻松写出数据迁移的rakefile。在demo/根目录下创建rakefile文件：

	require 'active_record'
	require 'yaml'
	require 'logger'
	
	task :default => :migrate
	
	task :migrate => :environment do
	  ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
	end
	
	task :environment do
	  ActiveRecord::Base.establish_connection(YAML::load(File.open('db/database.yml')))
	  ActiveRecord::Base.logger = Logger.new(File.open('db/database.log', 'a'))
	end

只要在终端中执行rake命令就可能完成数据迁移：

	$ rake
	==  CreateUsers: migrating ====================================================
	-- create_table(:users)
	   -> 0.0020s
	==  CreateUsers: migrated (0.0040s) ===========================================

实际上现在还无法得出这样的输出，因为还没有编写迁移代码文件。那么迁移文件写在哪儿呢？在demo/db/migrate/目录中专门用来放置数据迁移代码，比如现在我们在该目录下新建一个迁移文件001_create_users.rb，写入迁移代码：

	class CreateUsers < ActiveRecord::Migration  
	  def change  
	    create_table :users do |t|  
	      t.string :name  
	      t.integer :age  
	    end 
	  end  
	end  

现在执行rake命令才能得出上面给出的正确输出。

最后给出示例应用的最终目录结构：

![image](http://f.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=8350422bd309b3deefbfe46dfc841dbc/9358d109b3de9c8204461ccc6e81800a19d84356.jpg?referer=16e32c709045d688fa158794ad4c&x=.jpg)