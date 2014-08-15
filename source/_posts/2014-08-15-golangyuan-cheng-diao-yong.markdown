---
layout: post
title: "golang远程调用"
date: 2014-08-15 20:22:34 +0800
comments: true
categories: go
---

go语言的远程调用包`net/rpc`非常简单，而且由于go不支持动态链接，如果想要获得程序的动态性，那么就只好依赖于远程调用。

<!-- more -->

### 服务端

首先定义服务契约：

```go contract.go  服务契约定义
package contract

import (
    "fmt"
)

type Args struct {
    Name string
    Age  int
}

type Sign int

func (t *Sign) Content(args *Args, reply *string) error {
    *reply = fmt.Sprintf("%s is %v years old.", args.Name, args.Age)
    return nil
}
```

契约的定义规则很简单：服务函数必须满足 `func (t *T) MethodName(argType T1, replyType *T2) error`的形式，方法的第一个参数是服务接收的传入参数，第二个引用参数是返回值。契约服务的接收者可以随意定义，如此处的`Sign`，没有特别的用处。

然后看看服务端怎么注册服务：

```go main.go 服务端
package main

import (
    "contract"
    "log"
    "net"
    "net/http"
    "net/rpc"
)

func main() {
    ct := new(contract.Sign)
    rpc.Register(ct)
    rpc.HandleHTTP()
    l, e := net.Listen("tcp", ":8843")
    if e != nil {
        log.Fatal("listen error:", e)
    }
    http.Serve(l, nil)
}
```

### 客户端

在很多其他语言中，实现远程调用的契约，必须共享一套契约代码，比如android的远程调用，必须将服务端定义的契约编译成`.class`文件然后提供给客户端使用，否则同一个服务类是无法在客户端和服务端对应起来的。

但是，go是不需要的，至于为什么后面再讲。

回头想想也是，既然不支持动态链接，客户端怎么使用契约文件编译结果呢？

```go main.go 客户端
package main

import (
    "fmt"
    "log"
    "net/rpc"
)
func sync_invoke() string {
    client, err := rpc.DialHTTP("tcp", "127.0.0.1:8843")
    if err != nil {
        log.Fatal("dialing:", err)
    }
    args := &struct {
        Name string
        Age  int
    }{"jack", 23}
    var reply string
    err = client.Call("Sign.Content", args, &reply)
    if err != nil {
        log.Fatal("error:", err)
    }
    return reply
}
func async_invoke() string {
    client, err := rpc.DialHTTP("tcp", "127.0.0.1:8843")
    if err != nil {
        log.Fatal("dialing:", err)
    }
    args := &struct {
        Name string
        Age  int
        Sex string
    }{"jack", 23,"male"}
    var reply string
    future := client.Go("Sign.Content", args, &reply, nil)
    // wait for call end
    futureResult := <-future.Done
    if futureResult.Error != nil {
        log.Fatal("error:", err)
    }
    c := futureResult.Reply.(*string)
    return *c
}

func main() {
    c := sync_invoke() 
    fmt.Println("get sync result:", c)
    c = async_invoke()
    fmt.Println("get async result:", c)
}
```

输出结果：

```
get sync result: jack is 23 years old.
get async result: jack is 23 years old.
```

go同时提供了同步和异步调用远程服务两种选择。代码自解释性很强，故无须赘述了。

**注意**细节的同学可能发现了，上面异步调用部分的代码传递的参数结构体args和服务端定义的参数Args并不一致，那是因为go的远程调用默认采用encoding/gob编码和解码，它是一种类似与json的数据分享方式，但更加结构化，关于gob的详情可以google，这里不细说。由于使用gob，使得go的rpc可以接受`相似`结构，而不强求服务端和客户端服务参数完全一致。

简单来说，两个结构的**导出成员**完全一致，或者其中一个缺失一部分，或者其中一个多出一部分都算是相似结构。