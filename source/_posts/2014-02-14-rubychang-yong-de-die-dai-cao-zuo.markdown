---
layout: post
title: "ruby常用的迭代操作"
date: 2014-02-14 17:18:15 +0800
comments: true
categories: ruby
---

ruby是一门可以用sexy来形容的语言，下面就列举几个sexy的迭代操作。

<!-- more -->

###1. each简单迭代

each是ruby中非常常见的遍历操作，她是年老色衰的for直接替代品。如果需要索引，则可以使用each_with_index方法。

	words=%w(good god ruby sexy girl run)
	words.each do |word|
		puts word
	end

###2. find 查找单个元素

查找到第一个符合条件的元素，find。

	words=%w(good god ruby sexy girl run)
	words.find do |word|
		word.start_with? 'r'
	end
	=> "ruby"

###3. select 选取元素

选取所有符合条件的元素，select。

	words=%w(good god ruby sexy girl run)
	words.select do |word|
		word.start_with? 'r'
	end
	=> ["ruby", "run"]

###4. reject 剔除元素

剔除部分符合条件的元素，reject。

	words=%w(good god ruby sexy girl run)
	words.reject do |word|
		word.start_with? 'r'
	end
	=> ["good", "god", "sexy", "girl"]

###5. map 转换元素

转换每个元素，map。

	words=%w(good god ruby sexy girl run)
	words.map do |word|
		word.capitalize
	end
	=> ["Good", "God", "Ruby", "Sexy", "Girl", "Run"]

###6. uniq 唯一化

剔除相等的元素，uniq。

	words=%w(good god ruby sexy girl run run god Run)
	words.uniq
	=> ["good", "god", "ruby", "sexy", "girl", "run", "Run"]

也可以在块中指定比较的方法，自定义比较的对象。

	words=%w(good god ruby sexy girl run run god Run)
	words.uniq do |w|
		w.downcase
	end
	=> ["good", "god", "ruby", "sexy", "girl", "run"]

###7. group_by 分组元素

分组元素，这个真的很sexy，group_by。

按首字母分组：

	words=%w(good god ruby sexy girl Run)
	words.group_by do |w|
		w.capitalize[0]
	end
	=> {"G"=>["good", "god", "girl"], "R"=>["ruby", "Run"], "S"=>["sexy"]}

###8. sort_by 排序元素

排序元素，sort_by。

	words=%w(good god ruby sexy girl Run)
	words.sort_by do |w|
		w.length
	end
	=> ["Run", "god", "sexy", "ruby", "girl", "good"]

###9. zip 组合元素

组合遍历元素，zip。

	words=%w(good god ruby sexy girl Run)
	numbers=(11..16)
	symbols=%w(+ - * / = %)
	words.zip(symbols,numbers)
	=> [["good", "+", 11], ["god", "-", 12], ["ruby", "*", 13], ["sexy", "/", 14], ["girl", "=", 15], ["Run", "%", 16]]

###10. inject 累积元素

累积元素求值，这是我最喜欢的一个，inject。

	numbers=(1..10)
	numbers.inject do |memo,value|
		memo=memo+value
	end
	=> 55

这是比较简单的，举个难点的，如果需要将hash表 {a:1,b:2,c:3,d:1} 的键和值相互调换，即键变值，值变键，并且重复的值变成键后将原本的键变成列表形式的值。

	tbl={a:1,b:2,c:3,d:1}
	tbl.inject({}) do |memo,(k,v)|
		memo[v]||=[]
		memo[v]<<k
		memo
	end
	=> {1=>[:a, :d], 2=>[:b], 3=>[:c]}

###11. partition 分组操作

将元素分为符合条件和不符合条件的两个组。
   
	(1..6).partition { |v| v.even? }  #=> [[2, 4, 6], [1, 3, 5]]
###12. flatten扁平化列表

将多级列表合并为一个单独列表，以上例的列表为例。

	[[2, 4, 6], [1, 3, 5]].flatten  #=>[ 2 , 4 , 6 , 1 , 3 , 5 ]

###13. rotate旋转列表

	a = [ "a", "b", "c", "d" ]
	a.rotate         #=> ["b", "c", "d", "a"]
	a                #=> ["a", "b", "c", "d"]
	a.rotate(2)      #=> ["c", "d", "a", "b"]
	a.rotate(-3)     #=> ["b", "c", "d", "a"]

###14. join将列表转换为一个字符串

	[ "a", "b", "c" ].join        #=> "abc"
	[ "a", "b", "c" ].join("-")   #=> "a-b-c"
