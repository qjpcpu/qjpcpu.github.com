---
layout: post
title: "axlsx报表工具(三)创建图表"
date: 2014-02-15 00:42:48 +0800
comments: true
categories: ruby
---

### 饼图

axlsx创建饼状图非常简单，上图：

![image](../images/20131222120934093.jpeg)

	wb.add_worksheet(:name => "Pie Chart") do |sheet|
	  sheet.add_row ["First", "Second", "Third", "Fourth"]
	  sheet.add_row [1, 2, 3, 4]
	  sheet.add_chart(Axlsx::Pie3DChart, :start_at => [0,2], :end_at => [5, 15], :title=> 'dark corner here') do |chart|
	    chart.add_series :data => sheet["A2:D2"], :labels => sheet["A1:D1"]    #数据点序列及其名称
	    chart.d_lbls.show_val = true       #是否在饼状图中显示数值
	    chart.d_lbls.show_percent = true    #是否在饼状图中显示所占百分比
	    chart.d_lbls.d_lbl_pos = :outEnd    #图例位于图标外部
	    chart.d_lbls.show_leader_lines = true  #是否显示数据和数值间的指示线
	  end
	end

在add_chart方法中，第一个参数指定图标的类型Aslsx::Pie3DChart，而start_at和end_at分别指定图表的左上角单元格和右下角+1单元格，注意图中饼图的右下角单元格是E15即[4,14]，而end_at是[5,15]，所以称为右下角+1单元格，此外注意和excel编号不同，这里单元格序号是从0开始的。

* chart.add_series方法是创建图表的主要方法，用来添加点序列的值及其名称。
* chart.d_lbls是Data Lables的缩写，顾名思义就是数据标签。

饼图中每块扇形的颜色是自动生成的，如果想要手动指定也是可以的：

	chart.add_series :data => sheet["A2:D2"], :labels => ["A1:D1"], :colors => ['FF0000', '00FF00', '0000FF']

### 折线图

![image](../images/20131222122241750.jpeg)

	 wb.add_worksheet(:name => "Line Chart") do |sheet|
	  sheet.add_row ['l1','l2','l3','l4']
	  sheet.add_row [1, 2, 100, '=sum(A2:C2)']
	  sheet.add_chart(Axlsx::Line3DChart, :start_at => [0,2], :end_at => [8, 17], :title => "Chart") do |chart|
	    chart.add_series :data => sheet["A2:D2"], :labels => sheet["A1:D1"], :title => 'bob'
	    chart.d_lbls.show_val = true
	    chart.d_lbls.show_cat_name = true
	    chart.catAxis.tick_lbl_pos = :none   #不在横轴上显示坐标
	
	  end
	 end

chart.d_lbls.show_val表示显示数值，而chart.d_lbls.show_cat_name表示显示每个数值的名称。

### 柱形图

![image](../images/20131222122546203.jpeg)

	wb.add_worksheet(:name => "Bar Chart") do |sheet|
	  sheet.add_row ["A Simple Bar Chart"]
	  sheet.add_row ["First", "Second", "Third"]
	  sheet.add_row [1, 2, 3]
	  sheet.add_chart(Axlsx::Bar3DChart, :start_at => "A4", :end_at => "F17") do |chart|
	    chart.add_series :data => sheet["A3:C3"], :labels => sheet["A2:C2"], :title => sheet["A1"]
	    chart.valAxis.label_rotation = -45
	    chart.catAxis.label_rotation = 45
	    chart.d_lbls.d_lbl_pos = :outEnd
	    chart.d_lbls.show_val = true
	
	    chart.catAxis.tick_lbl_pos = :none
	  end
	  sheet.add_chart(Axlsx::Bar3DChart, :barDir => :col,:start_at => "A17", :end_at => "F30") do |chart| #barDir指定方向:bar或:col
	    chart.add_series :data => sheet["A3:C3"], :labels => sheet["A2:C2"], :title => sheet["A1"]
	    chart.valAxis.label_rotation = -45
	    chart.catAxis.label_rotation = 45
	    chart.d_lbls.d_lbl_pos = :outEnd
	    chart.d_lbls.show_val = true
	
	    chart.catAxis.tick_lbl_pos = :none
	  end
	 end

这里的图表位置start_at和end_at使用了和上面不同的方式，直接使用单元格名称如A4，F17，但end_at仍然是右下角单元格+1。其他代码的自解释性很强，无须赘述了。