---
layout: post
title: "命令行参数"
date: 2014-05-02 01:14:33 +0800
comments: true
categories: docker
---

阅读docker源码第一个文件`DOCKER/docker/docker.go`，这是docker的主函数所在的地方。简单来说，这个文件的代码就做了一件事：解析命令行参数，然后根据命令行参数再分流到各种子过程的调用。

<!-- more -->

### flag

go语言默认使用flag包来做命令行参数解析，对于这个包的使用可以参考官方文档的说明。但归结起来，使用这个包大概有三个步骤：

1. 使用`flag.XXX`函数定义参数名及保存参数的变量
2. 调用`flag.Parse()`进行参数的解析，解析结果被保存在定义的各个变量里
3. 读取这些变量值

但docker里定义参数的函数和标准库不太一样，docker的flag可以使用参数名数组来定义参数。比如在标准flag库里定义一个显示版本号的参数：

	flVersion = flag.Bool("v", false, "Print version information and quit")

但在docker里是这样定义的：

```go docker/docker.go
	flVersion = flag.Bool([]string{"v", "-version"}, false, "Print version information and quit")
```
	
所以即可以使用`docker -v`也可以使用`docker --version`来显示版本号。

### docker的实现

docker在这里玩了个小trick，首先它重写了标准库的flag，并将包名由`flag`改成`mflag`，然后这样导入包：

	import flag "github.com/dotcloud/docker/pkg/mflag"

所以在docker里造成直接使用flag的假象。

那么，docker是怎样实现多多参数名的支持的？

首先，mflag将`Flag`的结构体定义参数名`Name`修改成数组形式`Names`：

```go pkg/mflag/flag.go
	type Flag struct {
	    Names    []string // name as it appears on command line
	    Usage    string   // help message
	    Value    Value    // value as set
	    DefValue string   // default value (as text); for usage message
	}
```
	
然后还利用了flag标准库本身的特性，在同一个变量上可以绑定多个参数名:

	var de string
	flag.String(&de,"a","","argument")
	flag.String(&de,"b","","argument")

即可以用`cmd -a val`也可以用`cmd -b val`来调用，变量de的值都会被绑定为`val`。

除此之外，docker的`mflag`包还多定义了一种“隐藏参数”：以`#`开头来定义参数名：

	flag.Bool([]string{"#iptables", "-iptables"}, true, "Enable Docker's addition of iptables rules")
	
即，使用`-iptables`和`--iptables`都是有效的，但是在显示`Usage`时仅显示`--iptables`参数的使用说明，这是docker在不断升级更新时，所采用的一种兼容策略吧，允许旧参数的使用并给出警告，但以无帮助信息的方式不推荐旧参数。

实际实现也很简单，就是在帮助函数里去除对旧参数的说明：

```go pkg/mflag/flag.go
func (f *FlagSet) PrintDefaults() {
    f.VisitAll(func(flag *Flag) {
        format := "  -%s=%s: %s\n"
        if _, ok := flag.Value.(*stringValue); ok {
            // put quotes on the value
            format = "  -%s=%q: %s\n"
        }
        names := []string{}
        for _, name := range flag.Names {
            if name[0] != '#' {
                names = append(names, name)
            }
        }
        if len(names) > 0 {
            fmt.Fprintf(f.out(), format, strings.Join(names, ", -"), flag.DefValue, flag.Usage)
        }
    })
}
```
	
在10-12行，如果参数名定义时以`#`开头则不打印参数帮助。

好吧，参数解析源码其实和标准库大部分都是一样的，看到不一样的地方就行了，今天就到这里吧。