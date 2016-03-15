---
layout: post
title: "http原理"
date: 2016-03-15 14:10:51 +0800
comments: true
categories: go
---

Go语言中处理http请求主要涉及两个对象: [ServeMux](https://golang.org/pkg/net/http/#ServeMux)和[http.Handler接口](https://golang.org/pkg/net/http/#Handler)。

ServeMux即http请求路由，将http请求分发到注册的对应路由处理方法中。http.Handler及http的路由处理接口，该接口实际上仅包含一个方法**ServeHTTP**:

```go src/net/http/server.go
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}
```
<!-- more -->

### 基本原理

下面我们创建一个简单的HTTP服务，该服务仅返回一个文本页面:

```go main.go
package main

import (
	"fmt"
	"net/http"
)

type TextHandler struct {
	word string
}

func (th *TextHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("I wanna say: " + th.word))
}

func main() {
	mux := http.NewServeMux()
	th := &TextHandler{word: "cool"}
	mux.Handle("/", th)

	fmt.Println("Server started...")

	http.ListenAndServe(":3000", mux)
}
```

访问[http://localhost:3000](http://localhost:3000)，页面返回`I wanna say: cool`。

`http.NewServeMux`创建出新的路由容器，`http.NewServeMux#Handle`方法将路由及其处理函数注册到路由容器，ServeMux内部包含一个map结构，用来存取http URL对应的处理器。

而`http.ListenAndServe`需要指定服务监听地址和一个Handler对象，及方法签名如下:

```go src/net/http/server.go
func ListenAndServe(addr string, handler Handler) error
```

而ServeMux对象其实也定义了一个ServeHTTP的对象方法，所以ServeMux is a Handler，能够传入ListenAndServe方法启动服务。

**综上，使用ServeMux组装路由,再将它作为一个Handler交给http启动服务。当服务接收到一个http请求后，就根据路由中配置的规则选择对应的handler进行处理，实际的处理逻辑则由该handler的ServeHTTP方法实现。**

> 路由分发的逻辑具体实现可以查看[http包源码](https://golang.org/src/net/http/server.go)

### 标准用法

#### 1.简化代码

基本原理中的例子足以展示出golang的http处理原理，由于自定义的handler均必须实现http.Handler接口,这样会导致多余声明代码的产生。所以http包提供了一个帮助方法`http.HandlerFunc`将方法参数和`ServeHTTP`相同的方法转换为`http.Handler`。 

```go main.go
package main

import (
	"fmt"
	"net/http"
)

func saySomething(w http.ResponseWriter, r *http.Request) {
	word := "cool"
	w.Write([]byte("I wanna say: " + word))
}

func main() {
	mux := http.NewServeMux()
	th := http.HandlerFunc(saySomething)
	mux.Handle("/", th)
	fmt.Println("Server started...")
	http.ListenAndServe(":3000", mux)
}

```

实际上，`http.HandlerFunc`不是一个方法调用，仅仅是一个类型转换。

```go 源码src/net/http/server.go
type HandlerFunc func(ResponseWriter, *Request)
// ServeHTTP calls f(w, r).
func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
	f(w, r)
}
```

所以，自定义的请求处理函数(`saySomething`)仅需要保持参数定义和`http.Handler`接口相同即可，将该自定义函数做类型转换为`HandlerFunc`即可。另外，由源码可以看出，函数类型`HandlerFunc`同时也实现了`http.Handler`，所以能够注册到`ServeMux`中。

#### 2.保持封装

代码看起来缺失简单了一些，然而这样却破坏了逻辑的封装性：`saySomething`中包含了硬编码的参数`word`。这可以使用闭包来解决:

```go main.go
package main

import (
	"fmt"
	"net/http"
)

func saySomething(word string) http.Handler {
    // 闭包装入变量word
	f := func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("I wanna say: " + word))
	}
	return http.HandlerFunc(f)
}

func main() {
	mux := http.NewServeMux()
	th := saySomething("cool")
	mux.Handle("/", th)
	fmt.Println("Server started...")
	http.ListenAndServe(":3000", mux)
}
```

**http服务中出现了很多名称，命名比较相近，这里汇总解释下:**

* **ServeMux**，路由容器，http服务中的路由规则统一在这里定义，启动服务后路由的分发自然也由其处理
* **http.Handler**,请求处理器，每个处理http请求的处理器均需要实现该接口`ServeHTTP`
* **http.HandlerFunc**,帮助"方法"(实际是一个函数类型声明),将参数和`ServeHTTP`相同的普通函数转换为一个`http.Handler`

### http中间件

golang中http处理流程是这样的:

    ServeMux ==>  Middleware Handler ==> Application Handler

**中间件**:

* 中间件也是一个http.Handler，所以必须实现`ServeHTTP`
* 构建完整的中间件调用链，保证覆盖上图的中间件调用关系，并作为handler注册到`http.ServeMux`

一个中间件示例:

```go
func exampleMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    // 中间件逻辑在这里实现
    next.ServeHTTP(w, r)
  })
}
```

由这个中间件定义可以看出中间件链的构建方式: 函数嵌套。

```go
http.Handle("/", middlewareOne(middlewareTwo(finalHandler)))
```

看一个实际的例子:

```go main.go
package main

import (
  "log"
  "net/http"
)

func middlewareOne(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    log.Println("Executing middlewareOne")
    next.ServeHTTP(w, r)
    log.Println("Executing middlewareOne again")
  })
}

func middlewareTwo(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    log.Println("Executing middlewareTwo")
    if r.URL.Path != "/" {
      return
    }
    next.ServeHTTP(w, r)
    log.Println("Executing middlewareTwo again")
  })
}

func final(w http.ResponseWriter, r *http.Request) {
  log.Println("Executing finalHandler")
  w.Write([]byte("OK"))
}

func main() {
  finalHandler := http.HandlerFunc(final)

  http.Handle("/", middlewareOne(middlewareTwo(finalHandler)))
  http.ListenAndServe(":3000", nil)
}
```

访问[http://localhost:3000](http://localhost:3000)可以从日志看出中间件调用顺序:

    $ go run main.go
    2014/10/13 20:27:36 Executing middlewareOne
    2014/10/13 20:27:36 Executing middlewareTwo
    2014/10/13 20:27:36 Executing finalHandler
    2014/10/13 20:27:36 Executing middlewareTwo again
    2014/10/13 20:27:36 Executing middlewareOne again

#### 中间件链构造方式

上面例子的中间件链是比较常见的构造方式，然而多少有些可怕。而[Alice](https://github.com/justinas/alice)将中间件链的构造简化了许多:

    Middleware1(Middleware2(Middleware3(App)))

转化为

    alice.New(Middleware1, Middleware2, Middleware3).Then(AppHandler)
    // or 
    alice.New(Middleware1, Middleware2, Middleware3).ThenFunc(AppFunc)

### 参考文献

文中主要内容来自参考文献第一、二条

* [A Recap of Request Handling in Go](http://www.alexedwards.net/blog/a-recap-of-request-handling)
* [Making and Using HTTP Middleware](http://www.alexedwards.net/blog/making-and-using-middleware)
* [net/http](https://golang.org/src/net/http/server.go)
