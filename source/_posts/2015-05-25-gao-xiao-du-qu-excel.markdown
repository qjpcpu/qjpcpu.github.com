---
layout: post
title: "高效读取excel"
date: 2015-05-25 11:11:02 +0800
comments: true
categories: ruby 
---

前面介绍ruby写excel文件的一个很cool的gem包`axlsx`,这里介绍另一个高效读取excel的包`creek`。

一个读一个写，ruby轻松搞定execel处理。
<!-- more -->

#### 安装
```bash
gem install creek
```

#### 使用
`creek`本身的使用非常简单:

```ruby creek_demo.rb
require 'creek'
creek = Creek::Book.new "specs/fixtures/sample.xlsx"
sheet= creek.sheets[0]

# 注:获取行数不能用size方法
puts sheet.rows.count # => 100

sheet.rows.each do |row|
  puts row # => {"A1"=>"Content 1", "B1"=>nil, C1"=>nil, "D1"=>"Content 3"}
end

sheet.rows_with_meta_data.each do |row|
  puts row # => {"collapsed"=>"false", "customFormat"=>"false", "customHeight"=>"true", "hidden"=>"false", "ht"=>"12.1", "outlineLevel"=>"0", "r"=>"1", "cells"=>{"A1"=>"Content 1", "B1"=>nil, C1"=>nil, "D1"=>"Content 3"}}
end

sheet.state   # => 'visible'
sheet.name    # => 'Sheet1'
sheet.rid     # => 'rId2'
```
#### 性能
读取并遍历一个16M左右17608行的xlsx文件，benchmark:

```bash
--------------- total: 84.040000sec   ----------------
  user     system      total        real
 84.920000   0.680000  85.600000 ( 86.084133)
```

P.S. 无法和其他读取excel的gem做对比，因为试着做对比测试时发现其他gem根本卡在读取操作那不动了。



