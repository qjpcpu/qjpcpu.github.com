---
layout: post
title: "ruby类和模块的关系"
date: 2014-02-14 14:47:25 +0800
comments: true
categories: ruby
---

学习ruby入门的时候，很容易被其类和模块的小trick给迷惑住了，这里为了整理自己的理解，就写出来看看吧。

<!-- more -->

### 1.ruby一切皆对象

ruby是彻底地面向对象，你见到的一切构件都是对象。数字是对象，字符串是对象，类也是对象，模块也是对象，甚至类的类(Class)也是对象......


	irb(main):001:0> 1.is_a? Object
	=> true
	irb(main):002:0> Object.is_a? Object
	=> true
	irb(main):003:0> Class.is_a? Object
	=> true
	irb(main):007:0> class Test
	irb(main):008:1> end
	=> nil
	irb(main):009:0> Test.is_a? Object
	=> true

其实在这里，像我这样从传统面向对象语言过来的初学者往往会提出疑问：在Java中，我们总可以明显地看出是那个对象在调用方法，但当我进入irb时，并没有创建任何对象，怎么可以调用puts等等方法？这里先不讨论puts方法来源于哪儿，但是当开始执行第一行ruby代码之前，实际上就存在一个对象了。这个对象叫main，是Object的对象。

	irb(main):015:0> self
	=> main
	irb(main):016:0> self.class
	=> Object

此时所处的环境被称为Top Level Context（顶级上下文）。是ruby调用栈的顶端，通常（不在TLC时并非main在充当当前对象）你调用puts等方法时就是这个main对象在充当调用者（接收者）。

### 2.ruby的类和模块

ruby的类和模块可以统一看成是对象的分类，ruby中每个对象都有一个分类：

	irb(main):017:0> Object.class
	=> Class
	irb(main):018:0> t=Test.new
	=> #<Test:0x1a5aa48>
	irb(main):019:0> t.class
	=> Test
	irb(main):020:0> Kernel.class
	=> Module
	irb(main):023:0> Module.class
	=> Class
	irb(main):024:0> Class.class
	=> Class

可以看到，对象的分类是其普通类，类的分类是Class，Kernel模块的分类是Module，Class的分类也是Class，Module的分类也是类。
甚至于，在ruby中，我们可以认为只有一种分类，那就是模块Module，因为Class是从Module继承而来。

	irb(main):011:0> Class.ancestors
	=> [Class, Module, Object, Kernel, BasicObject]
     
除了很少的几个区别，几乎可以将类和模块一视同仁，类只不过是增强后的模块。那么，ruby中其他普通类和Class/Module有什么关系呢？答案是，其他类（模块）不过是Class(Module)的实例而已。

	irb(main):028:0> Test.instance_of? Class
	=> true
	irb(main):013:0> Kernel.instance_of? Module
	=> true

根据这个原理，就可以像下面这样定义新类：

	irb(main):029:0> MyClass=Class.new do
	irb(main):030:1* def say
	irb(main):031:2> puts "I am MyClass"
	irb(main):032:2> end
	irb(main):033:1> end
	=> MyClass
	irb(main):034:0> m=MyClass.new
	=> #<MyClass:0x1a4f798>
	irb(main):035:0> m.say
	I am MyClass
	=> nil

使用Class.new操作就新建了一个类，把这个类赋值给MyClass，这个新类就定义出来了，可以像使用其他类一样使用。这段代码除了证明普通类不过是Class的实例外，还说明了另一个问题：类名不过是一个常量而已。我们可以查看当前常量列表来验证：

	irb(main):038:0> Object.constants.grep /MyClass/
	=> [:MyClass]
       

### 3.ruby的方法查找

当在ruby程序中调用一个方法时，ruby解释器以方法的接收者或者self为起点，沿着该对象的祖先链往上查找方法，直到找到这个方法或者抛出异常。

以在TLC中调用puts方法为例，此时puts方法的接收者隐式由self充当，而此时的self是Object类的对象main，那么查看Object类的方法：

	irb(main):041:0> Object.methods.grep /puts/
	=> []

在Object中显然并不存在puts方法，那么查看Object的祖先链：

	irb(main):042:0> Object.ancestors
	=> [Object, Kernel, BasicObject]
	       沿着祖先链，我们查看Kernel的方法：
	
	irb(main):043:0> Kernel.methods.grep /puts/
	=> [:puts]

显然puts方法位于Kernel中。从前面知道，Kernel是一个模块，它被混入(Mixin)类中，通常当模块include混入时，模块的方法就成为类的实例方法，由于Kernel模块混入了Object类中，所以在ruby代码的任何地方都可以调用puts方法，因为ruby的几乎全部的类都继承自Object。

> PS.关于private方法：
> 
> ruby中的private方法有时让人很懊恼。但实际上需要记住的只有一点：private方法只能在隐含的接收者self上被调用，但private方法调用的查找规则和其他方法是一样的。

所以，即便是TLC中main对象拥有puts方法，但却不能这样调用：

	irb(main):046:0> self.puts
	NoMethodError: private method `puts' called for main:Object
        from (irb):46
        from C:/RailsInstaller/Ruby1.9.3/bin/irb:12:in `<main>'

另外，不要和Java等语言中的private混淆，ruby的private方法时可以在子类中调用的：

	irb(main):052:0> class Dad
	irb(main):053:1> private
	irb(main):054:1> def say
	irb(main):055:2> puts "Dad says private"
	irb(main):056:2> end
	irb(main):057:1> end
	=> nil
	irb(main):058:0> class Son <Dad
	irb(main):059:1> def talk
	irb(main):060:2> say
	irb(main):061:2> puts "son talk"
	irb(main):062:2> end
	irb(main):063:1> end
	=> nil
	irb(main):064:0> s=Son.new
	=> #<Son:0x1c90cb0>
	irb(main):065:0> s.talk
	Dad says private
	son talk

最后，补充说一下几个常用方法的调用：

	irb(main):067:0> Object.private_methods.grep /method/
	=> [:define_method, :method_missing,.........]

Objcet的method_missing和define_method都是其私有方法，为什么在方法内部调用method_missing正确，而调用define_method就会报错，必须在类上下文充当self时才能调用define_method？

Object#method_missing方法是Object的一个private方法，不能显示地使
用接收者调用，但所有对象都可以隐式调用该方法。
而define_method实际上是Module#define_method方法，该方法是Module的private实例方法，而Class又继承了Module类，所以它变成了Class的实例方法，由于所有的普通类都是Class的实例，所以define_method就成为了所有普通类的类方法，所以在类上下文中能够使用define_method此时self由类充当，而不能在某个具体对象充当self时调用该方法。
