---
layout: post
title: "rails ActiveRecord数据库关系1:1"
date: 2014-02-14 21:25:17 +0800
comments: true
categories: rails
---

如图所示，在demo数据库中有suppliers和accounts两张表。一个supplier有一个account，一个account属于一个supplier，是一个1:1关系。

![1-1](http://b.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=e9efbd7d0ef3d7ca08f63f73c224cf34/730e0cf3d7ca7bcb7b8b3d6cbc096b63f724a885.jpg?referer=c1b305f367380cd7bf0996dd089b&x=.jpg)

1. 建立数据表

		 $ rails g model supplier name:string
		 $ rails g model account supplier_id:integer account_number:string
		 $ rake db:migrate

2. 修改model，添加关系

在这个1:1关系中，accounts拥有外键supplier_id，所以需要在account.rb中添加belongs_to关系，相对应在supplier.rb中添加has_one关系。注意rails的约定，用rails g命令创建model时使用单数形式（首字母大小写无所谓），得到的数据库的表名是小写的复数形式，model的类名是驼峰形式的单数形式，model文件名是小写单数形式。
> account.rb

	class Account < ActiveRecord::Base
	  belongs_to :supplier
	end

> supplier.rb

	class Supplier < ActiveRecord::Base
	    has_one :account
	end

对于1:1关系，有几个常用的可选项：

:dependent: 对于has_one关系的一方（supplier)，可以添加:dependent选项为destroy, delete,nullify，destroy表示删除supplier会同时删除它拥有的account(包括内存对象和数据库记录)，delete表示删除supplier会删除拥有account的数据库记录但不调用其destroy销毁内存对象，nullify表示删除supplier会解除和account的关系，即仅将其拥有account中的外键置为NULL。

:inverse_of: 该选项成对出现，保证一对关系中的数据同步，避免出现下面的情况：

	s=Supplier.first
	a=s.account
	s.name==a.supplier.name #=>true
	s.name="new_name"
	s.name==a.supplier.name #=>false

所以，再次修改model：

> account.rb

	class Account < ActiveRecord::Base
	  belongs_to :supplier, :inverse_of=>:account
	end

> supplier.rb

	class Supplier < ActiveRecord::Base
	    has_one :account, :dependent=>:destroy, :inverse_of=>:supplier
	end

3. 关系操作

在建立1:1关系后，关系的两端都自动添加了如下方法来创建关系：

	association(force_reload = false)
	association = (associate)
	build_association(attributes = {})
	create_association(attributes = {})

即，在rails中可以这样使用：

	s = Supplier.first
	a = s.account #获取关系
	s.account = Account.find(11) #创建关系
	#仅仅创建关系，这个acc并没有被保存
	acc = s.build_account(account_number:"1234")
	#这个新的acc被创建并保存
	acc = s.create_account(account_number:"4589")

需要注意的是，对于association=()方法，在1:1关系的两端的工作是不一样的。

	#关系被自动保存到数据库
	@supplier.account = @account
	#关系保存在内存，除非现实调用save，否则关系不会保存到数据库
	@account.supplier = @supplier #并未保存关系
	@account.save #保存了二者的关系

这个问题对于1：n关系也同样存在，在1的一方建立关系会自动保存，在多的一方建立关系不会自动保存。对于什么时候应该使用save方法，什么时候不必使用，有一个好记的规则，如果model包含外键，那么在该model上调用association=()建立的关系需要save（如上例的account），反过来如果model不包含外键，则不需要（如上例的supplier）。

解除关系：

	@supplier.account = nil
	@supplier.account.delete

在本例中，上述两种办法都可以解除关系，并且会删除account对象。

