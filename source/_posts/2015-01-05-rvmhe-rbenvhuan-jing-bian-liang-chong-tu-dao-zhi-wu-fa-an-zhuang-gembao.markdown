---
layout: post
title: "rvm和rbenv环境变量冲突导致无法安装gem包"
date: 2015-01-05 18:11:47 +0800
comments: true
categories: ruby
---

## 背景
root环境用rvm安装了ruby，但我需要在用户环境重装ruby，而且个人喜欢用rbenv，这就导致了我安装了rbenv的gem后，没有权限安装gem包。

<!-- more -->

## resolve
这种情况是rvm强制设置了`GEM_HOME`导致的，可以`gem env`查看：

    jason@mac:~$ gem env
    RubyGems Environment:
      - RUBYGEMS VERSION: 2.0.14
      - RUBY VERSION: 2.0.0 (2014-11-13 patchlevel 598) [x86_64-linux]
      - INSTALLATION DIRECTORY: /usr/local/rvm/gems/ruby-2.0.0-p353
      - RUBY EXECUTABLE: /home/jason/.rbenv/versions/2.0.0-p598/bin/ruby
      - EXECUTABLE DIRECTORY: /usr/local/rvm/gems/ruby-2.0.0-p353/bin
      - RUBYGEMS PLATFORMS:
        - ruby
        - x86_64-linux
      - GEM PATHS:
         - /usr/local/rvm/gems/ruby-2.0.0-p353
         - /home/jason/.rbenv/versions/2.0.0-p598/lib/ruby/gems/2.0.0/
      - GEM CONFIGURATION:
         - :update_sources => true
         - :verbose => true
         - :backtrace => false
         - :bulk_threshold => 1000
      - REMOTE SOURCES:
         - https://rubygems.org/

可见GEM PATHS里优先选择了rvm的gem路径，所以需要重设GEM_HOME

    export GEM_HOME=$HOME/.rbenv/versions/2.0.0-p598/lib/ruby/gems/2.0.0/

但是，最好的办法是在~/.bash_profile(centos,ubuntu中是.bashrc)中`eval "$(rbenv init -)"`前加上：

    unset GEM_PATH
    unset GEM_HOME

这样也可以清除rvm的设置，使rbenv的变量被正确设置.
