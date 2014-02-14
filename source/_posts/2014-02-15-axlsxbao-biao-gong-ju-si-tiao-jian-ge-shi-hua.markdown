---
layout: post
title: "axlsx报表工具(四)——条件格式化"
date: 2014-02-15 00:47:04 +0800
comments: true
categories: ruby
---

### 定义格式化操作

条件格式化风格定义也是使用格式化定义语句add_style，不同的是必须将type指定为:dxf。

	# define the style for conditional formatting
	profitable = book.styles.add_style( :fg_color => "FF428751", :type => :dxf )
	unprofitable = book.styles.add_style( :fg_color => "FF0000", :type => :dxf )

条件格式化有四种类型cellIs，colorScale，dataBar，iconSet。

### cellIs

cellIs条件格式化使用得较为普遍，即对满足条件的单元格更改字体颜色，字体大小，背景色等等。

![image](../images/20131222124537296.jpeg)

对于B列，如果数值大于100000表示盈利，则更改字体颜色；对于亏损的，则在C列中将百分比小于100%的赤字显示。

	book.add_worksheet(:name => "Cell Is") do |ws|
	
	  # 产生20行数据
	  ws.add_row ["Previous Year Quarterly Profits (JPY)"]
	  ws.add_row ["Quarter", "Profit", "% of Total"]
	  offset = 3
	  rows = 20
	  offset.upto(rows + offset) do |i|
	    ws.add_row ["Q#{i}", 10000*((rows/2-i) * (rows/2-i)), "=100*B#{i}/SUM(B3:B#{rows+offset})"], :style=>[nil, money, percent]
	  end

	# 格式化条件>100000
	  ws.add_conditional_formatting("B3:B100", { :type => :cellIs, :operator => :greaterThan, :formula => "100000", :dxfId => profitable, :priority => 1 })
	# 格式化条件0.00%<x<100%
	  ws.add_conditional_formatting("C3:C100", { :type => :cellIs, :operator => :between, :formula => ["0.00%","100.00%"], :dxfId => unprofitable, :priority => 1 })
	end

add_conditional_formatting方法指定条件格式化，类型type是cellIs，条件由operator和formula共同指定，dxfId就是我们上面定义的格式化操作，priority优先级数值越小，优先级越高。

### colorScale

![image](../images/20131222125354250.jpeg)

colorScale是以颜色渐变的方式来格式化表格。

	book.add_worksheet(:name => "Color Scale") do |ws|
	  ws.add_row ["Previous Year Quarterly Profits (JPY)"]
	  ws.add_row ["Quarter", "Profit", "% of Total"]
	  offset = 3
	  rows = 20
	  offset.upto(rows + offset) do |i|
	    ws.add_row ["Q#{i}", 10000*((rows/2-i) * (rows/2-i)), "=100*B#{i}/SUM(B3:B#{rows+offset})"], :style=>[nil, money, percent]
	  end
	
	  color_scale = Axlsx::ColorScale.new
	  ws.add_conditional_formatting("B3:B100", { :type => :colorScale, :operator => :greaterThan, :formula => "100000", :dxfId => profitable, :priority => 1, :color_scale => color_scale })
	end

大于100000的单元格颜色越来越深，而小于的单元格越来越浅。

### dataBar

dataBar格式化能够在单元格中同时显示数值和一个柱形图，非常直观漂亮。

![image](../images/20131222125728531.jpeg)

	book.add_worksheet(:name => "Data Bar") do |ws|
	  ws.add_row ["Previous Year Quarterly Profits (JPY)"]
	  ws.add_row ["Quarter", "Profit", "% of Total"]
	  offset = 3
	  rows = 20
	  offset.upto(rows + offset) do |i|
	    ws.add_row ["Q#{i}", 10000*((rows/2-i) * (rows/2-i)), "=100*B#{i}/SUM(B3:B#{rows+offset})"], :style=>[nil, money, percent]
	  end
	
	  data_bar = Axlsx::DataBar.new
	  ws.add_conditional_formatting("B3:B100", { :type => :dataBar, :dxfId => profitable, :priority => 1, :data_bar => data_bar })
	end

### iconSet

iconSet方式是对于满足条件和不满足条件的单元格分别使用不同的图标。

![image](../images/20131222125946421.jpeg)

	book.add_worksheet(:name => "Icon Set") do |ws|
	  ws.add_row ["Previous Year Quarterly Profits (JPY)"]
	  ws.add_row ["Quarter", "Profit", "% of Total"]
	  offset = 3
	  rows = 20
	  offset.upto(rows + offset) do |i|
	    ws.add_row ["Q#{i}", 10000*((rows/2-i) * (rows/2-i)), "=100*B#{i}/SUM(B3:B#{rows+offset})"], :style=>[nil, money, percent]
	  end
	
	  icon_set = Axlsx::IconSet.new
	  ws.add_conditional_formatting("B3:B100", { :type => :iconSet, :dxfId => profitable, :priority => 1, :icon_set => icon_set })
	end
