---
layout: post
title: "Go学习笔记-函数和包"
date: 2014-02-14 18:15:26 +0800
comments: true
categories: go
---

### 函数定义

go语言中使用func关键字定义函数，如main函数的定义：

	func main() {
		 fmt.Println("main function")
	}

定义一个具有参数和返回值的函数：

	func sum(a int,b int) int {
		return a+b
	}

### 多值返回

go语言的函数可以有多个返回值，它是真正的多值返回，这个特性让ruby之父都有些艳羡呢（ruby的多值实际上是返回的列表）。

	func sum(a int,b int) (int,bool){
		s := a+b
		t := true
		return s,t
	}

调用函数时，可以这样获取多个值：

	m,n := sum(1,2)
	//如果，不需要全部的返回值，可以用_来替代
	m,_ := sum(1,2)

多值返回还有一个很cool的特性，如果返回值使用了命名参数，那么函数最后可以直接使用空的return语句，go函数会自动寻找匹配返回值的变量返回：

	func sum(a int,b int) (s int,t bool){
		s = a+b
		t = true
		return 
	}

### 闭包

go语言另一个很cool的特性就是它支持了闭包，虽然这在众多的动态语言中已经被玩坏了，不过go语言明确对它提出了支持，这仍旧是令人十分激动的。

	func main() {
	     x := 0
	     increment := func() int {
	           x++
	return x }
	     fmt.Println(increment())
	     fmt.Println(increment())
	}

### defer

go语言的defer延迟执行是一个很有意思的特性，它将defer后的函数推迟到退出函数的最后一刻才执行：

	func main() {
	    defer second()
		first() 
	}

main函数里执行的真正顺序是first()，然后才是 second()，defer保证其后的函数会最后执行，甚至在发生运行时异常后，也会保证执行。

	package main
	import "fmt"
	func main() {
	     defer func() {
	           str := recover()
	           fmt.Println(str)
	     }()
	     panic("PANIC")
	}

### 指针

go的指针和c语言的指针用法非常类似，不再赘述。另外go还提供了另一种创建指针的方式，new关键字，它返回对应类型的地址：

	func one(xPtr *int) {
	     *xPtr = 1
	}
	func main() {
	     xPtr := new(int)
	     one(xPtr)
	     fmt.Println(*xPtr) // x is 1
	}

### go保留函数

> 本节内容来自：Go Web编程

> Go里面有两个保留的函数:init函数(能够应用于所有的package)和main函数(只能应用于package main)。 这两个函数在定义时不能有任何的参数和返回值。虽然一个package里面可以写任意多个init函数,但这无论是对 于可读性还是以后的可维护性来说,我们都强烈建议用户在一个package中每个文件只写一个init函数。
> 
> Go程序会自动调用init()和main(),所以你不需要在任何地方调用这两个函数。每个package中的init函数都是可选的,但package main就必须包含一个main函数。
> 
> 程序的初始化和执行都起始于main包。如果main包还导入了其它的包,那么就会在编译时将它们依次导入。有时一 个包会被多个包同时导入,那么它只会被导入一次(例如很多包可能都会用到fmt包,但它只会被导入一次,因为没 有必要导入多次)。

#### 包的引入

我们在写Go代码的时候经常用到import这个命令用来导入包文件,而我们经常看到的方式参考如下:

	import(
	   "fmt"
	)


然后我们代码里面可以通过如下的方式调用

	fmt.Println("hello world")


上面这个fmt是Go语言的标准库,其实是去goroot下去加载该模块,当然Go的import还支持如下两种方式来加载自己写的模块:

1. 相对路径

		import “./model”   //当前文件同一目录的model目录,但是不建议这种方式来import

2. 绝对路径

		import “shorturl/model”   //加载$GOPATH/src/shorturl/model模块

上面展示了一些import常用的几种方式,但是还有一些特殊的import,让很多新手很费解,下面我们来一一讲解一下 到底是怎么一回事

1. 点操作

我们有时候会看到如下的方式导入包

	import(
	   . "fmt"
	)

这个点操作的含义就是这个包导入之后在你调用这个包的函数时,你可以省略前缀的包名,也就是前面你调用的`fmt.Println("hello world")`可以省略的写成`Println("hello world")`

2. 别名操作

别名操作顾名思义我们可以把包命名成另一个我们用起来容易记忆的名字

	import(
	   f "fmt"
	)

别名操作的话调用包函数时前缀变成了我们的前缀,即 f.Println("hello world")

3. _操作

这个操作经常是让很多人费解的一个操作符,请看下面这个import

	import (
	     "database/sql"
	     _ "github.com/ziutek/mymysql/godrv"
	)
		     	    
_操作其实是引入该包,而不直接使用包里面的函数,而是调用了该包里面的init函数