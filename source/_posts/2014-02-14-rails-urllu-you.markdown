---
layout: post
title: "rails URL路由"
date: 2014-02-14 23:26:35 +0800
comments: true
categories: rails
---

rails URL路由的最权威文档当然是其官方站点Rails routing from the outside in，我这里只提几个文档中常用的要点。

### 1.CRUB

由resources建立的资源，是rails中最常见的路由方式，不用多说。

	resources :photos

### 2.单例资源

单例资源也比较常用，官方文档上举的例子很形象也很常见，用户user需要拥有一个profile资源，而每个用户必然只有一个profile，所以如果生成类似/profiles/:id的URL显然是不美观的，此时就需要单例资源，单例资源的生成使用的是单数形式方法resource：

	resource :profile

该语句生成的路由如下：

![image](http://d.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=97c9415095dda144de096cb7828ca19f/902397dda144ad34c29c62c4d2a20cf431ad8556.jpg?referer=68c064fc8e5494eede353a29e34c&x=.jpg)

### 3.嵌入的路由

适用于某种资源必须依赖于另一种资源才有意义，比如某些comment必然在针对的event下存在，所以comment就必须依赖于event。

	resources :events do
	    resources :comments
	end

![image](http://e.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=8d06f6a8b4fd5266a32b3c119b23e616/38dbb6fd5266d01605e9646b952bd40734fa3584.jpg?referer=12da45f1bb014a90d829728d739b&x=.jpg)

对应的也自动生成了诸如event_comment_path之类的url 帮助方法。对于嵌入式资源，官方建议不要超过两层。最简单的理由，路由层次过深，除了增加逻辑的复杂度外，也得不到任何好处。

### 4.namespace和scope路由

以下规则同时适用于resources和controller。

比如，如果想要在特定的命名空间(admin)下访问某个资源(post)，这时就可以利用namespace。

	namespace :admin do
	  resources :posts
	end

此时，处理该路由的controller是Admin::PostsController，体现在rails工程中是在controller文件夹下的admin文件夹下的posts_controller.rb文件。而产生的路由全部以/admin开头：

![image](http://g.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=b8309d15d2160924d825a21ee43c44c7/5366d0160924ab1899e61b7437fae6cd7a890b84.jpg?referer=b7cc85e3f403738d875d3812759b&x=.jpg)

一言以蔽之，由namespace产生的资源路由，controller和url都由该namespace作“前缀”。

如果需要让资源路由没有前缀，而又希望该路由url被某个模块下的controller受理，那么就需要使用
scope。

	scope module: 'admin' do
	  resources :posts
	end

![image](http://h.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=8e21687d79ec54e745ec1a1b8903ea6d/b90e7bec54e736d18030694b99504fc2d5626956.jpg?referer=7e1763ad9e82d158e2956c81d74c&x=.jpg) 

由rake routes输出可以看出，路由url没有了admin前缀，而posts资源都由admin模块下的Admin::PostsController受理。

一言以蔽之，带module的scope产生的资源路由，路由url无“前缀”，controller以module指定模块为“前缀”。

反过来，如果希望给资源附加一个前缀，而由普通controller受理该url，则需要另一种形式的scope：

	scope '/admin' do
	  resources :posts
	end

![image](http://h.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=6c4451220db30f24319aec06f8aea07e/9f510fb30f2442a7cefe07e6d343ad4bd0130284.jpg?referer=91d5f909d8b44aed00598ad46e9b&x=.jpg)

此时，资源posts每个url都附加了/admin为前缀，而受理这些url的是PostsController。

一言以蔽之，这种形式的scope产生的资源路由，路由url有“前缀”，controller无“前缀”。

另外，这种形式的路由还有一种简写：

	resources :posts, path: '/admin/posts'

该简写和使用scope产生的结果完全一样。不过，path还有另外的用途，如果保持controller及url helper不变，仅仅希望为url路由中的资源改个名称，这时path就派上用场了：

	resources :posts, path: '/articles'

![image](http://d.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=596a1640ca95d143de76e42643cbf33f/d833c895d143ad4bcadebc8380025aafa50f0684.jpg?referer=35be44a7b11c87018fa186d6629b&x=.jpg)

### 5.新增RESTful动词

以下规则同样适用于resources和controller。

	resources :photos do
	  get 'preview', on: :member
	end

该语句为某个特定photo新增了一个preview动作，该动作是一个get请求，默认photos_controller中存在一个preview方法处理该动作。

类似的，如果需要为photos集合新增一个动词，只需要将语句中member改成collection即可。

如果，需要为特定photo增加多个动词preview1和preview2，改成下面的形式即可，甚至可以指定
controller中处理该请求的方法，以及自定义url helper：

	resources :photos do
	  member do
	    get 'preview1'=>:pre1, as:"p1"
	    get 'preview2'=>:pre2, as:"p2"
	  end
	end

![image](http://c.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=15e98dd4db33c895a27e987ee12802cd/43a7d933c895d143b7861e6071f082025baf0784.jpg?referer=5020e10089d4b31ca92ba08b619b&x=.jpg)

### 6.非resourceful路由

#### 使用参数：

	controller :photos do
	  get 'check/:id',:to=>:check
	end

产生的路由输出如下：

	GET /check/:id(.:format) photos#check

在执行该get请求如/check/23，后photos_controller的check方法受理该请求，并在params中将参数设置为23。

#### 限制参数格式：

	get 'photos/:id', to: 'photos#show', constraints: { id: /[A-Z]\d{5}/ }

该路由规则能接受/photos/A12345却不能接受/photos/893。

#### 指定请求的默认类型：
    
	get 'articles/:id', to: 'articles#show', defaults: { format: 'xml' }
若get请求/articles/2，该路由规则会自动将params的params[:format]置为"xml"。

该方法仅仅是在请求未指定format时指定默认类型，如果需要某个controller仅接受某些格式的请求如xml和json，则可以在该controller类定义中添加如下代码，这在书写api时常常用到：

	respond_to :json, :xml

#### 更换资源的controller：

如果不希望为某个资源使用默认的controller，则：

	resources :photos, controller: 'images'

此时photos资源的所有请求都由images_controller受理，而photos的路由url和url helper都不变。

#### 限制资源的默认动作：

如果仅希望使用资源的部分动作，如仅使用资源photos的index和show动作：

	resources :photos, only: [:index, :show]

或者使用除了destroy动作外的所有默认动作：

	resources :photos, except: :destroy
还可以使用:all（所有默认动作），:none（没有默认动作）：

	resources :photos, :only=>:none

#### 为new和edit的url路由改名：

	resources :photos, path_names: { new: 'make', edit: 'change' }

产生的新路由为：

	/photos/make
	/photos/1/change

而此时受理该路由的方法仍为new和edit，即controller中的方法并未改名。