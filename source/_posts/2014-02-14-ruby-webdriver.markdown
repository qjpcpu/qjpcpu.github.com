---
layout: post
title: "ruby webdriver"
date: 2014-02-14 17:13:12 +0800
comments: true
categories: ruby
---

###前言

Watir Webdriver是用ruby操作webdriver的很酷的方式，通常被用来做一些rails app的测试。

###Example

下面的示例是一个网站的登录示例：

	require 'watir-webdriver'
	b = Watir::Browser.new
	b.driver.manage.window.maximize
	b.goto "http://xx.com"
	b.link(:text => 'Create Account').click
	b.text_field(:id => 'signupEmail').focus!.set "some@example.com"
	b.text_field(:id => 'signupPassword').focus!.set "1234"
	b.text_field(:id => 'passwordConfirm').focus!.set "1234"
	b.checkbox(:id=> 'notifyOptin').focus!.set true
	b.button(:id => 'signupSubmit').focus!.click
	# or you can use:
	# b.send_keys :enter
	b.text.include? 'Welcome to XX website'
	b.close

上面的示例中，很多text_field或button等元素使用了focus！方法，这是因为webdriver无法和浏览器中未显示的元素交互，否则会发生异常，当你拥有一个很长的列表在当前浏览器窗口中无法显示时，如果去和未显示的列表项交互就会发生这种异常。解决办法是调用元素的focus方法，focus方法会将该元素滚动到视野中，但focus方法默认返回nil，如果调用该方法多次就不是一个hacky way。所以需要为webdriver打个补丁，添加一个focus！方法：

	class Watir::Element
		def focus!
			self.focus unless self.visible?
			self
		end
	end

有的网站登录会使用一个frame来呈现登录窗口，webdriver可以很方便地和frame交互：

	b.frame(:id => "content_ifr").text_field(:id=>'signinEmail').set "s@gmail.com"
	b.frame(:id => "content_ifr").text_field(:id=>'signinEmail').set "234"

更多html元素的交互请看elements。
发送特定的按键：

	b.send_keys :enter
	b.element.send_keys [:control, 'a'], :backspace
	b.element.click(:shift, :control)