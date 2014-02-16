---
layout: post
title: "axlsx报表工具(一)安装及入门"
date: 2014-02-15 00:34:19 +0800
comments: true
categories: ruby
---

### 安装

axlsx是一个基于ruby的Office Open XML Spreadsheet报表生成工具，下图是它生成的一个报表截图

![axlsx](https://raw.github.com/randym/axlsx/master/examples/sample.png)

<!-- more -->

安装axlsx和安装其他gem一样：

	$ gem install axlsx

### 创建第一个报表

axlsx使用的对象和office文档使用的对象完全一样，workbook代表一个文档，worksheet代表一张表，row和cell代表行和单元格，基本上所有的对象顾名思义即可，而不需要了解文档ECMA规范。

比如要创建一张如图所示的报表：

![image](http://c.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=0b461ccc6e81800a6ae5890b810e42c7/cdbf6c81800a19d86620614631fa828ba61e4656.jpg?referer=5d8a74b17f1ed21b20de1bd5a24c&x=.jpg)

	require 'axlsx'
	
	p = Axlsx::Package.new
	wb = p.workbook
	
	wb.add_worksheet(:name => "Basic Worksheet") do |sheet|
	  sheet.add_row ["First Column", "Second", "Third","Total"]
	  sheet.add_row [1, 2, 3,"=SUM(A2:C2)"]
	  sheet.add_row ['This is a very very long sentence.']
	  sheet.merge_cells "A3:D3"
	end
	
	p.serialize 'basic.xlsx'

代码非常简单明了，创建worksheet，再一行行添加数据，在添加第二行数据时甚至使用了一个求和函数，所以我们使用过的Excel的知识完全可以直接拿过来使用，甚至对于较长的内容可以合并单元格，但这里没有居中显示所以还不够美观，美观的事情可以格式化来解决，不过这是下一篇的内容了。

最后一行是将报表序列化到xlsx格式的文件，该文件可以用MSOffice直接打开查看。