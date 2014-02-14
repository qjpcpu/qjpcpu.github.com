---
layout: post
title: "rails ActiveRecord数据库关系1:n"
date: 2014-02-14 22:05:20 +0800
comments: true
categories: rails
---

    如图所示，在demo数据库中有customers和orders两张表。一个customer有多个order，一个order属于一个customer，是一个1:n关系。
![1:n](../images/RailsActiveRecord数据库关系1vn-1.png)

1. 建立数据表

		$ rails g model customer name:string
		$ rails g model order customer_id:integer order_date:datetime
		$ rails g model rake db:migrate

2. 修改model，添加关系

在这个1:n关系中，orders拥有外键customer_id，所以需要在order.rb中添加belongs_to关系，相对应在customer.rb中添加has_many关系。注意rails的约定，用rails g命令创建model时使用单数形式（首字母大小写无所谓），得到的数据库的表名是小写的复数形式，model的类名是驼峰形式的单数形式，model文件名是小写单数形式。

类似1:1关系，同样添加inverse_of和dependent选项。此处dependent选项的多了一个delete_all，即:dependent=>:delete_all，表示移除customer时会删除其order的所有数据库记录，但不调用这些order的destroy方法销毁对象。

> customer.rb

	class Customer < ActiveRecord::Base
		has_many :orders, :dependent => :destory, :inverse_of => :customer
	end
	
> order.rb

	class Order < ActiveRecord::Base
		belongs_to :customer, :inverse_of => :orders
	end

3. 操作关系

1：n关系中，在belongs_to关系端添加的方法和1：1中类似，不再赘述。在has_many端添加了如下方法：

	collection(force_reload=false)
	collection<<(object, ...)
	collection.delete(object,...)
	collection = objects
	collection_singular_ids
	collection_singular_ids = ids
	collection.clear
	collection.empty?
	collection.size
	collection.find(...)
	collection.where(...)
	collection.exists?(...)
	collection.build(attributes={},...)
	collection.create(attributes={})

使用举例：

	c = Customer.first
	order_list = c.orders #获取customer c的所有orders
	c.orders.delete order_list.first #解除关系
	c.orders.clear #清空当前customer的所有order
	ar = c.order_ids # => [1,2,3,4,9,12]
	c.orders << Order.create( order_date:DateTime.now ) #自动保存关系到数据库
	c.orders.create(order_date:DateTime.now) #和上一行等同
	c.orders.build(order_date:DateTime.now) #需要手动保存该order对象
	c.orders.size #获取orders的数量
	c.orders.find 6 # 找到customer的orders中id为6的order
	c.orders.where :order_date=>DateTime.now
	c.orders.where("id > ?",6)
	c.orders.empty?

4. 特殊的1：n关系——自引用关联

如，一个Employee拥有多个下属，同时也拥有一个主管，这就是一个自引用关系表。

	$ rails g model employee name:string manager_id:integer
	$ rake db:migrate

> employee.rb

	class Employee < ActiveRecord::Base
		has_many :subordinates, :class_name=>'Employee', :forgeign_key=>'manager_id'
		belongs_to :manager, :class_name=>'Employee'
	end

建立好model后，和普通1：n关系使用方法并无二致：

	manger = Emloyee.where(manager_id:nil).first
	manager.subordinates.each do |s|
		puts s.name
	end

5. 特殊的1：n关系——多态关系

多态关系(polymorphic)可以看作是一种特殊的1：n关系。考虑一种情况，Emplyee和Picture是1：n的关系，Product和Picture也是1：n的关系，Company和Picture也是1：n的关系，这样，在Picture的model中就需要添加许多的belongs_to关系，这些belongs_to的功能是非常类似的，多态关系就是为了解决这类重复。

以Picture,Employee,Product为例，首先创建数据表。

	$ rails g model picture name:string owner_id:integer owner_type:string
	$ rails g model employee
	$ rails g model product

注意在创建pictures时，将所有拥有Picture的model称为owner（也可以取别的名称，如RailsGuide上取名为imageable，个人觉得称为owner更形象），并创建了owner_id和owner_type两个字段，分别表示拥有者model的id和类型。

修改model：

> product.rb

	class Product < ActiveRecord::Base
		has_many :picture, :as=>:owner
	end

> employee.rb

	class Employee < ActiveRecord::Base
		has_many :pictures, :as=>:owner
	end
	
> picture.rb

	class Picture < ActiveRecord:Base
		belongs_to :owner, :polymorphic => true
	end

所有拥有picture的model中，都在其has_many关系中添加了选项:as=>:owner，而picture的model中belongs_to关系添加了:polymorphic=>true选项。这样，如果以后还有新的model和picture是1:n的关系，那么在其中写入has_many :pictures,:as=>:owner即可，不必修改Picture的model及其数据表。

关系的使用：

	p1=Picture.create name:'picture-1'
	p2=Picture.create name:'picture-2'
	e=Employee.create
	pro=Product.create
	e.pictures<<p1
	pro.pictures<<p2
	
	p1.owner.class.name # => 'Employee'
	p2.owner.class.naem # => 'Product'