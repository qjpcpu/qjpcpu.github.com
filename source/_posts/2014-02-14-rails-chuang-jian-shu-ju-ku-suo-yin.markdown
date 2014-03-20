---
layout: post
title: "rails 创建数据库索引"
date: 2014-02-14 23:01:32 +0800
comments: true
categories: rails
---

以经典的customer-order为例

### 1. 在创建数据表时直接创建索引

```bash
rails g model customer
rails g model order customer:references
```

查看order的migration文件，rails自动为我们添加了index：

```ruby
class CreateOrders < ActiveRecord::Migration
	def change
		create_table :orders do |t|
				t.refercences :customer
				t.timestamps
		end
		add_index :orders, :customer_id
	end
end
```

<!-- more -->

### 2. 手动附加索引

此时创建数据表是以普通字段创建的外键

```bash
rails g model customer
rails g model order customer_id:integer
```

如果需要创建索引，就需要手动新建一个migration来添加索引：

```bash
rails g migration add_customer_id_index_to_orders
```

修改migration文件，手动添加index

```ruby
class AddCustomerIdIndexToOrders < ActiveRecord::Migration
	def change
		add_index :orders, :customer_id
	end
end
```

### 3. many-to-many关系中添加index

以man-address为例，直接创建中间表并不会自动添加索引，所以需要在中间表内手动添加索引：

```ruby
class AddAddressesMenTable < ActiveRecord::Migration
	def change
		create_table :address_men,:id=>false do |t|
			t.references :address, :null=>false
			t.references :man,:null=>false
		end
		add_index :addresses_men,[:address_id,:man_id]
	end
end
```

### 4. 建议

所有的外键最好都添加索引。