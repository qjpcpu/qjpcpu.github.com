---
layout: post
title: "Install and deploy rails on CentOS"
date: 2014-02-14 14:30:55 +0800
comments: true
categories: rails
---

### prerequisites:

I cover all these operations on CentOS 6.4 and with root, so if you encounter some privilege problem, try sudo. And, if using Ubuntu, you needn't worry about SELinux.

<!-- more -->

#### 1. install essentical library

	yum update
	yum install gcc g++ make automake autoconf curl-devel openssl-devel zlib-develhttpd-devel apr-devel apr-util-devel sqlite-devel gcc-c++

then compile and install nodejs

	wget http://nodejs.org/dist/v0.10.7/node-v0.10.7.tar.gz
	# then compile and install it

#### 2. install libyaml(needed by ruby)

	wget http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz
	tar xzvf yaml-0.1.4.tar.gz
	cd yaml-0.1.4
	./configure
	make
	make install

#### 3. install ruby

	wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p0.tar.gz
	# compile and install
	ruby –v # check ruby installed correctly

#### 4. install rubygems

	wget  http://production.cf.rubygems.org/rubygems/rubygems-2.0.3.tgz
	tar vxzf rubygems-2.0.3.tgz
	cd rubygems-2.0.3.tgz
	ruby setup.rb
	gem –v

#### 5. install rails

	gem update
	gem update --system
	gem install rails –V  #It really costs a longtime, enjoy a coffee now

Next,we talk about deploy on centos

#### 6. install passenger(follow the instructions to install extra lib)

	gem  install passenger
	passenger-install-apache2-module

#### 7. find the apache configure

	apachectl  –V | grep HTTPD_ROOT
	apachectl  –V | grep SERVER_CONFIG_FILE

Add code snippet below to apache config file

	<VirtualHost*:80>
	      ServerName   test.com
	      DocumentRoot  /var/www/html/blog/public   
	      <Directory  /var/www/html/blog/public>
	         AllowOverride all
	         Options -MultiViews
	      </Directory>
	</VirtualHost>

If something’s wrong, add line below then try again

	NameVirtualHost*:80

#### 8. config mysql database(if you use sqlite,skip this step)

If you use mysql in production, add below to gemfile

	group:production do
	    gem ‘mysql2’
	end

Then bundle install

	bundle install

Config mysql

	mysql–u root –p # login to mysqlserver
	mysql>create database depot_production character set utf8;
	mysql>grant all privileges on depot_production.*
	mysql>to ‘username’@’localhost’ identified by ‘password’;
	mysql>exit;

Modify the config/database.yml

	production:
	     adapter: mysql2
	     encoding: utf8
	     reconnect: false
	     database: depot_production
	     pool: 5
	     username: username
	     password: password
	     host: localhost

#### 9. apply your migrations

	rake db:setup RAILS_ENV='production'

#### 10. precompile the static resources

	bundle exec rake assets:precompile RAILS_ENV='production'

On centos, we must change selinux’s behavior(Everytime you deploy!)

#### 11. Temporarily go into SELinux permissive mode

	setenforce  0

#### 12. restart apache

	apachectl restart

#### 13. use your rails app for a while

#### 14. allow passenger run with selinux

Note: if can't find audit2allow, you should install it first, otherwise you can skip 2 commands below

	yum  provides  \*/audit2allow
	yum  install  policycoreutils-python
	grep httpd  /var/log/audit/audit.log | audit2allow -M passenger

install newly created selinux module

	semodule  -i passenger.pp

#### 15. switch selinux back to enforcing mode

	setenforce 1
