---
layout: post
title: "struct tags"
date: 2014-07-12 00:07:11 +0800
comments: true
categories: golang
---

### 结构体标签

在定义结构时，可以为struct定义一个标签，这个标签是作为结构体字段的一个附加属性，主要是反射包会使用到这个属性。

```go
package main

import (
	"fmt"
	"reflect"
)

func main() {
	type S struct {
		F string `species:"gopher" color:"blue"`
	}

	s := S{}
	st := reflect.TypeOf(s)
	field := st.Field(0)
	fmt.Println(field.Tag.Get("color"), field.Tag.Get("species"))

}
```

输出结果

```bash
blue gopher
```

结构体`S`的`F`成员具有两个属性`species`和`color`，其属性的值分别为`blue`和`gopher`。如果不使用反射去取这个属性，在定义时写不写属性都是无所谓的。

<!--more-->

在go中，tag的定义是有规定的：

> By convention, tag strings are a concatenation of optionally space-separated key:"value" pairs. Each key is a non-empty string consisting of non-control characters other than space (U+0020 ' '), quote (U+0022 '"'), and colon (U+003A ':'). Each value is quoted using U+0022 '"' characters and Go string literal syntax.

即：按照go的默认约定，tag以`key:value`的形式定义，多个`key:value`以空格分割，`key`不能是控制字符单引号、双引号和冒号，`value`需要用引号引起来。 

当然，也可以不遵守这个约定，因为具体怎么使用tag还是按照开发者自己的意愿来的。