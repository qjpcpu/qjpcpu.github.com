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