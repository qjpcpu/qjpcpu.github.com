---
layout: post
title: "你不知道的Go"
date: 2014-06-23 14:37:47 +0800
comments: true
categories: go
---

### 1.匿名结构

```go
var person struct {
    name      string
    age int
}
person.name="jack"
```

声明时初始化：

```go
st := struct {
	name string
	age  int
}{
	"Jack",
	12,
}
fmt.Println(st.name)
```

<!-- more -->

### 2.抢占式调度器

>In prior releases, a goroutine that was looping forever could starve out other goroutines on the same thread, a serious problem when GOMAXPROCS provided only one user thread. In Go 1.2, this is partially addressed: The scheduler is invoked occasionally upon entry to a function. This means that any loop that includes a (non-inlined) function call can be pre-empted, allowing other goroutines to run on the same thread.

从golang1.2起，携程调度器为抢占式的，但抢占发生在每次进入函数前，所以，如果循环内的函数被编译器优化成了inline function，那么自然不会发生调度。