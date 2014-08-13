---
layout: post
title: "js异步回调与闭包"
date: 2014-08-14 00:20:20 +0800
comments: true
categories: CoffeeScript
---

很多地方讲解`CoffeeScript/JavaScript`都用了这么一个例子：

```
chars = ['A', 'B', 'C']
for ch in chars
  setTimeout(->
    console.log ch
  ,10)
```

<!--more-->

这个结果会输出`C C C`而不是`A B C`，为什么会这样是因为js的异步机制，在普通代码执行完毕后才会处理事件，而在处理时间打印console时`ch`已经是`C`了，所以三个回调都会打印`C`。

给出的改进版本也很直观：

```
chars = ['A', 'B', 'C']
for ch in chars
  do (ch) ->
    setTimeout(->
      console.log ch
    ,10)
```

为啥这样改呢，其实原因严格来说和闭包有关系。

在第一个版本里，我们用了一个匿名函数把变量ch作为环境放入闭包，但是注意这个变量的作用域在for循环所在的整个范围内可见，闭包复制了dui这个变量的引用，所以当匿名函数实际调用时，变量的值已经被改变，导致得不到想要的输出。

而第二个版本将ch以函数参数的形式复制到了闭包内，这个匿名函数里的ch作用域仅在这个闭包小环境内，外部for循环仅改变外部的这个ch，所以复制到闭包内的ch是不变的；不信可以把do后面函数改成无参的，结果肯定还是打印三个C。