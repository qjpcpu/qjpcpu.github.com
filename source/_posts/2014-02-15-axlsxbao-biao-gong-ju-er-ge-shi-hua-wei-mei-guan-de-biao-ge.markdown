---
layout: post
title: "axlsx报表工具(二)格式化为美观的表格"
date: 2014-02-15 00:38:10 +0800
comments: true
categories: ruby
---

### 基础知识

axlsx的格式化使用Aslsx::Styles类来处理，通常使用Axlsx::Styles#add_style 帮助方法来添加格式，该方法定义：

	(Integer) add_style(options = {})

<!-- more -->

所有的格式设置操作都在options这个hash中指定，该hash的键名非常好记，下面是常见的键值列表：

	Options Hash (options):
	fg_color (String) — 字体颜色，如：FFFF0000
	sz (Integer) — 字体大小
	b (Boolean) — 是否粗体
	i (Boolean) — 是否斜体
	u (Boolean) — 是否加下划线
	strike (Boolean) — 是否加删除线
	shadow (Boolean) — 是否加阴影
	charset (Integer) — 字符集，可选的字符集列表：
	0   ANSI_CHARSET
	1   DEFAULT_CHARSET
	2   SYMBOL_CHARSET
	77  MAC_CHARSET
	128 SHIFTJIS_CHARSET
	129 HANGUL_CHARSET
	130 JOHAB_CHARSET
	134 GB2312_CHARSET
	136 CHINESEBIG5_CHARSET
	161 GREEK_CHARSET
	162 TURKISH_CHARSET
	163 VIETNAMESE_CHARSET
	177 HEBREW_CHARSET
	178 ARABIC_CHARSET
	186 BALTIC_CHARSET
	204 RUSSIAN_CHARSET
	222 THAI_CHARSET
	238 EASTEUROPE_CHARSET
	255 OEM_CHARSET
	
	
	family (Integer) — 字体，可选字体：
	0 Not applicable.
	1 Roman
	2 Swiss
	3 Modern
	4 Script
	5 Decorative
	6..14 Reserved for future use
	
	
	font_name (String) — 字体名称
	num_fmt (Integer) — 数字格式：可选格式：
	1 0
	2 0.00
	3 #,##0
	4 #,##0.00
	5 $#,##0_);($#,##0)
	6 $#,##0_);[Red]($#,##0)
	7 $#,##0.00_);($#,##0.00)
	8 $#,##0.00_);[Red]($#,##0.00)
	9 0%
	10 0.00%
	11 0.00E+00
	12 # ?/?
	13 # ??/??
	14 m/d/yyyy
	15 d-mmm-yy
	16 d-mmm
	17 mmm-yy
	18 h:mm AM/PM
	19 h:mm:ss AM/PM
	20 h:mm
	21 h:mm:ss
	22 m/d/yyyy h:mm
	37 #,##0_);(#,##0)
	38 #,##0_);[Red](#,##0)
	39 #,##0.00_);(#,##0.00)
	40 #,##0.00_);[Red](#,##0.00)
	45 mm:ss
	46 [h]:mm:ss
	47 mm:ss.0
	48 ##0.0E+0
	49 @
	
	
	format_code (String) — 自定义格式如'yyyy-mm-dd'，如果设置了该值，则num_fmt将被忽略.
	border (Integer|Hash) — 边框样式.
	bg_color (String) — 单元格背景色
	hidden (Boolean) — 是否隐藏单元格
	locked (Boolean) — 是否锁定单元格
	type (Symbol) — 风格类型，可选的类型有[:dxf, :xf]. :xf事默认类型
	alignment (Hash) — 对齐.该hash的包括：
	horizontal (Symbol)，该键对应的值包括有：
	:general
	:left
	:center
	:right
	:fill
	:justify
	:centerContinuous
	:distributed
	vertical (Symbol)，该键对应的值有：
	:top
	:center
	:bottom
	:justify
	:distributed
	textRotation (Integer)
	wrapText (Boolean)
	indent (Integer)
	relativeIndent (Integer)
	justifyLastLine (Boolean)
	shrinkToFit (Boolean)
	readingOrder (Integer)

### 格式化报表示例

格式化报表是以单元格为单位执行的，通常在添加行的时候，在add_row第二个hash参数里指定：

	sheet.add_row ['a', "b"], :style => [nil, header] #header是创建好的style
	#or
	sheet.add_row ["a', "b"], :style => header

如果style是一个列表，那么列表里每一个格式对应于行内每个单元格，也可以像第二行代码那样为整行指定同一种格式。

![image](http://b.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=9b79859e2c738bd4c021b23491b0f6eb/4bed2e738bd4b31cc6cc6ef885d6277f9f2ff885.jpg?referer=f3368c656f224f4a0e8e4723389b&x=.jpg)

下面是创建如图报表的部分代码：

``` ruby
require 'axlsx'

Axlsx::Package.new do |p|
  p.workbook do |wb|
    styles = wb.styles
    header     = styles.add_style :bg_color => "FFFF33",:fg_color=>"0033CC", :sz => 16, :b => true, :alignment => {:horizontal => :center}
    tbl_header = styles.add_style :bg_color=>"99FF33",:b => true, :alignment => { :horizontal => :center }
    ind_header = styles.add_style :bg_color => "FFDFDEDF", :b => true, :alignment => {:indent => 1}
    col_header = styles.add_style :bg_color => "FFDFDEDF", :b => true, :alignment => { :horizontal => :center }
    label      = styles.add_style :alignment => { :indent => 1 }
    money      = styles.add_style :num_fmt => 5
    t_label    = styles.add_style :b => true, :bg_color => "FFDFDEDF"
    t_money    = styles.add_style :b => true, :num_fmt => 5, :bg_color => "FFDFDEDF"

    wb.add_worksheet do |sheet|
      sheet.add_row               #添加空行
      sheet.add_row [nil, "College Budget"], :style => [nil, header]        #标题，大字体居中
      sheet.add_row
      sheet.add_row [nil, "What's coming in this month.", nil, nil, "How am I doing"], :style => tbl_header
      sheet.add_row [nil, "Item", "Amount", nil, "Item", "Amount"], :style => [nil, ind_header, col_header, nil, ind_header, col_header]
      sheet.add_row [nil, "Estimated monthly net income", 500, nil, "Monthly income", "=C9"], :style => [nil, label, money, nil, label, money]
      #省略部分代码
      %w(B4:C4 E4:F4 B11:C11 E11:F11 B2:F2).each { |range| sheet.merge_cells(range) }
      sheet.column_widths 2, nil, nil, 2, nil, nil, 2
    end
  end
  p.use_shared_strings = true
  p.serialize 'styles.xlsx'
end
```