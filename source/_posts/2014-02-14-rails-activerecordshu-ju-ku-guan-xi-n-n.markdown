---
layout: post
title: "rails ActiveRecord数据库关系n:n"
date: 2014-02-14 21:50:54 +0800
comments: true
categories: rails
---

如图所示，在demo数据库中有assemblies和parts两张表。一个assembly有多个part，一个part也拥有多个assembly，是一个n:n关系。

![n-n](http://c.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=85dca9420855b31998f982707392f31b/78310a55b319ebc49d5a93da8026cffc1e171656.jpg?referer=378ada0800087bf424fb62d9524d&x=.jpg)

<!-- more -->

1.建立数据表

由于n:n的关系是以中间表的形式表达的，所以需要创建图示中的三张表assemlies, parts和中间表assemlies_part。

	$ rails g model assembly name:string
	$ rails g model part part_number:string
	$ rails g migration CreateAssembliesAndParts 

编辑db/migrate/目录下新建的xxxx_create_assemblies_and_parts.rb文件，在该文件中定义中间表：

> 20130609063804_create_assemblies_and_parts.rb

	class CreateAssembliesAndParts < ActiveRecord::Migration
		def change
			create_table :assemblies_parts, :id=>false do |t|
				t.integer :assembly_id
				t.integer :part_id
			end
		end
	end

 注意，该表包含n:n的两端表的主键，且自身不使用主键，故:id=>false。

另外，该中间表的表名是“assemblies_part“，以中间的下划线连接两张表，并且按照字母顺序小在前字母顺序大的在后排列，如果创建”part_assemlies“表，则rails可能找不到该中间表。

实际上，rails是以string的”<“操作来比较单词的，所以，如果不确定哪个表在前哪个在后，可以使用该操作符确定一下再创建表。比如有两张表”devil_x“和"devilx"（为什么会有人取这么奇怪的表名呢），那就需要自己来确认一下中间表的表名：

	irb(main):002:0> 'devil_x'<'devilx'
	=> true

所以，中间表的表名应该是“devil_x_devilx”。

最后，确认创建数据表：

	$ rake db:migrate

2. 修改model，添加关系

在关系的两端都需要添加has_and_belongs_to_many。

> assembly.rb

	class Assembly <ActiveRecord::Base
		has_and_belongs_to_many :parts
	end

> part.rb

	class Part < ActiveRecord::Base
		has_and_belongs_to_many :assemblies
	end

3. 操作关系

在n:n关系的两端都添加了如下方法：

	collection(force_reload=false)
	collection<<(object, ...)
	collection.delete(object, ...)
	collection = objects
	collection_singular_ids
	collection_singular_ids = ids
	collection.clear
	collection.empty?
	collection.size
	collection.find(...)
	collection.where(...)
	collection.exists?(...)
	collection.build(attributes = {})
	collection.create(attributes = {})

可以看到，添加的方法和has_many关系添加的方法相同，所以就不再重复介绍使用方法。