---
layout: post
title: "rake based application"
date: 2014-02-15 00:04:13 +0800
comments: true
categories: ruby
---

### 1.什么是rack

rack是基于ruby的web服务器接口，它将http协议以非常简单的方式包裹起来，为web服务器和应用提供一致性的接口。rack被用于几乎所有的ruby web应用开发框架中。这是维基百科上给出的一个基于rack的ruby应用：

	app = lambda do |env|
	  body = "Hello, World!"
	  [200, {"Content-Type" => "text/plain", "Content-Length" => body.length.to_s}, [body]]
	end
	 
	run app

重点是第三行，一个基于rack的ruby应用只需要一个包含call方法的对象，在调用call方法后该对象会返回形如第三行的一个列表，该列表包含三个元素：第一个元素是这次http请求的返回状态码200，第二个元素是一个返回的http响应headers的hash表，第三个元素是http响应体的列表，所以该列表的形式为：

	[ status_code, headers, body ]

### 2.一个简单的rack-based-application

编写一个最简单的rack based application，ok，需要一个能响应call方法的对象，在该对象上调用call方法能返回[ status_code, headers, body ]列表。在文件夹rack_based下新建simple.ru文件，*.ru被称为rakcup文件，rack使用该文件来启动rack应用。该文件内容为：

	run lambda { |env| [200,{'Content-Type'=>'text/plain'},['OK']]}

That's all.这个基于rack的应用已经编写完成了，在terminal中键入下面命令即可启动这个应用了：

	rackup rack_based/simple.ru

rack使用默认的内置WEBrick服务器，用rackup命令在端口9292启动该应用：

	JasondeMacBook-Pro:Projects jason$ rackup rack_based/simple.ru 
	Thin web server (v1.6.1 codename Death Proof)
	Maximum connections set to 1024
	Listening on 0.0.0.0:9292, CTRL+C to stop

在浏览器中访问http://localhost:9292即可看到页面显示“OK”，说明应用正常工作了。

Rails也是基于rack的框架，所以，rails的rackup配置文件是位于应用根目录下的config.ru：

	# This file is used by Rack-based servers to start the application.
	
	require ::File.expand_path('../config/environment',  __FILE__)
	run Rails.application

所以，Rails.application也能响应call方法。

另外，call方法还带有一个env参数，该参数是一个hash表，包含了请求所有的环境信息，rack应用可以根据env信息给予不同的响应，如下面将simple.ru略作修改，使得它可以返回所有的请求信息：

	module Simple
		class Application
			def self.call(env)
				[200,{'Content-Type'=>'text/plain'},[env.to_s]]
			end
		end
	end
	run Simple::Application

启动该应用，则可以看到结果：

![image](http://a.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=6bc04cf1d358ccbf1fbcb53f29e3cd03/9d82d158ccbf6c815814c9abbe3eb13533fa4056.jpg?referer=0e96044c8594a4c25334d21ba04c&x=.jpg)

### 3.middleware

这是一个rack应用的请求栈：

![image](http://e.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=70915c2796eef01f491418c0d0c5e818/8d5494eef01f3a29e9eb308d9b25bc315c607c56.jpg?referer=639819647d3e6709e71770cfbc4c&x=.jpg)

浏览器发出http请求到web Server，web server 再将请求转交给rack，rack负责将请求转交给应用程序栈。在应用栈中，请求经过一层层的中间层middleware后，最好才传达给rack应用，譬如rails的应用的controller最后来处理请求，当rack应用处理完请求后，又逐层返回，最后由rack上交给web server完成响应。注意，并非每次请求都需要完成从上到下的全部栈层次，比如请求一个存在的静态文件，就可能直接由处理静态文件的middleware发送文件，而根本不会将请求传递到rack应用controller中去。

由这张图可以看出来，rack是web server和应用之间的桥梁，或者说适配器。另外，rack应用处在请求栈的最后一层，web请求经过了无数的middleware后才真正到达应用这里。middleware所起的作用和java struts中的拦截器概念非常相似，它们都负责将请求逐层包裹最后递交给应用的是一个非常友好的请求包，使得应用可以更方便地处理逻辑。
      
下面就来创建一个自定义的middleware，该middleware可以将请求网页内所有\<h1>标记内的内容的e改写成大写的X。

首先新建一个rails app，在新建完成后，实用下面命令可以查看rails已经使用的middleware：

	rake middleware
	
	use Rack::Sendfile
	use ActionDispatch::Static
	......
	use Rack::Head
	use Rack::ConditionalGet
	use Rack::ETag
	run Demo::Application.routes

现在在应用的lib目录下新建文件link_jumbler.rb，文件app/lib/link_jumbler.rb的内容：

	require 'nokogiri'
	
	class LinkJumbler
		def initialize(app,letters)
			@app=app
			@letters=letters
		end
	
		def call(env)
			status, headers, response = @app.call(env)
			body=Nokogiri::HTML(response.body)
			body.css("h1").each do |a|
				@letters.each do |f,r|
					a.content=a.content.gsub f.to_s,r.to_s
				end
			end
	
			[status,headers,[body.to_s]]
		end
	end

首先，在initialize方法中，接受了两个参数，一个是app参数，它会在各个middleware中传递，需要对它调用call方法。另一个参数letters是我们这个middleware需要的参数，这个参数来源是挂载middleware时产生的。不同middleware的传递的这个参数不同，也可能根本没有这个额外的参数。在call方法中，先对@app调用了call方法获得了一个rack风格的响应结果，这里利用nokogiri解析结果，并做出修改，最后返回结果。在java struts中有个前拦截器和后拦截器，从这里也可以看出middleware也可以有相同的功能，比如这里就是对结果作处理，属于一个后处理的middleware。

然后将这个middleware添加到该应用的middleware栈中（看到letters哪儿来的了吧），在app/config/application.rb中添加
`config.middleware.use LinkJumbler,{"e"=>"X"}`
添加完成后app/config/application.rb文件内容为：

	require File.expand_path('../boot', __FILE__)

	require 'rails/all'
	require File.expand_path('../../lib/link_jumbler', __FILE__)

	Bundler.require(:default, Rails.env)
	
	module Demo
	  class Application < Rails::Application
	    config.middleware.use LinkJumbler,{"e"=>"X"}
	  end
	end

再次执行rake middleware命令，可以看到LinkJumbler被添加到最后一层middleware：

	use Rack::Sendfile
	use ActionDispatch::Static
	......
	use Rack::Head
	use Rack::ConditionalGet
	use Rack::ETag
	use LinkJumbler
	run Demo::Application.routes

启动该rails应用，可以看到和标准rails欢迎界面的区别了吗？

![image](http://b.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=513d3845adc379317968862cdbffc678/f636afc379310a559ad424b7b54543a983261084.jpg?referer=65c5a1751f950a7b2c227af4509b&x=.jpg)