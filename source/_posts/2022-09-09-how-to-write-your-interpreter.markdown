---
layout: post
title: "怎样写一个解释器"
date: 2022-09-09 11:57:00 +0000
comments: true
categories: programming
---

写一个解释器，通常是设计和实现一个编程语言的第一步,或者如果我们想要一种自定义程度较高的 DSL，通常也不得不自行去实现解释器。而如何实现一个解释器，网络上的资料其实也并不算多，所以我这里简单做个分享。

<!-- more -->

* 目录
{:toc}


# 写在前面

写一个解释器，通常是设计和实现一个编程语言的第一步,或者如果我们想要一种自定义程度较高的 DSL，通常也不得不自行去实现解释器。而如何实现一个解释器，网络上的资料其实也并不算多，所以我这里简单做个分享。


要完整实现一个编译器/解释器，需要语法设计到编译前后端的完整实现，这涉及到巨大的工作量。但通常我们只需要能够实现 DSL，使得 DSL 能够依托于我们主语言环境运行即可，不需要考虑编译后端的问题。所以本文的解释器仅涉及到编译前端流程，后端执行细节交给宿主语言运行时。

此外，如果一开始就选择非常复杂的语言如 Python、Ruby或Haskell, 会让我们掉入词法/语法解析的深坑，但对学习书写解释器没什么帮助，所以我们选择了语法规则简单的 lisp 来实现一个解释器。

另外，主语言使用 Golang, 除了语言本身比较简单，也为了读者对照实验没有环境部署的焦虑。

> If you don't know how compilers work, then you don't know how computers work.
>
> http://norvig.com/lispy.html 
> Steve Yegge.

# Lisp 语法

考虑到很多国内的同学可能没有接触过 lisp，这里首先简单介绍下其语法。

* golang

```go
if x > 0 {
  return fn(arr[i] + 3 * i, []string{"a", "b"})
}
```

* lisp

```clojure
(if (> x 0)
  (fn (+ (array_get arr i) (* 3 i)) 
      (list "a" "b")))
```

如上例所示，尽管golang 相较于其他语言，其语法已经非常简单，但是它仍然有数十个关键字，几个中置操作符, 操作优先级、逗号、各种括号等等，其语法规范仍然是比较多的；而相对来说，lisp 的语法规范就简单很多： 

* lisp 代码仅包含表达式，不包含语句，即，每一句lisp 必定都会返回值；
* 数字、字符串、符号均称为「原子」，原子不可分解；
* 除了原子外所有东西都是「列表」，列表以 `(`开头,`)`结尾；列表的第一个元素要么是一个关键字，要么是一个函数调用；

lisp 的这种设计导致代码可读性略有下降，但是却带来易解析、表意性强、代码和数据统一等诸多优点，因此长期是国外CS教学的首选语言。

# lis.go 计算器

我们本次的目标是基于 lisp 在 golang 是实现一个计算器。该计算器支持以下一些表达式:

| Expression | Syntax | Semantics and Example |
|------------| -------| ----------------------|
| 符号 | symbol | 一个符号通常引用了一个值，如 (define r 10) 表示符号 r 引用了值 10 | 
| 字面量| number | 比如数字 12 |
| 条件分支| (if test conseq alt) | 如果 test 为 true，则返回 conseq，否则返回 alt |
| 变量绑定| (define symbol expr) | 定义一个符号 symbol,且将其值绑定为 expr |
| 函数调用 | (proc arg ...) | 如果 proc 是关键字，如 if，则执行分支逻辑，否则寻找对应函数进行调用|

# 解释器工作流程

解释器执行通常包含两步：

* Parsing

解析代码生成抽象语法树,这一步通常叫 `parse`。

* Execution

对 AST 求值，返回我们想要的结果,这一步通常叫 `eval`。

下图是解释器工作的简单示例:

![parsing-execution](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/parsing-and-execution.png)

如下代码是是`parse`和`eval`工作的代码示例：

```go
>> program := "(begin (define r 10) (* pi (* r r)))"

>> parse(program)
['begin', ['define', 'r', 10], ['*', 'pi', ['*', 'r', 'r']]]

>> eval(parse(program))
314.1592653589793
```

# Get started

## 类型定义

首先，我们定义好 lis.go 需要的基本类型:

```go
// 所有的表达式都需要实现 Expression 接口,该接口仅仅是一个标记接口
type Expression interface {
	Sexpr() string
}

// 符号类型
type Symbol string
// 列表类型,其实是一个单向链表,每个节点存储当前表达式和下一个节点指针
type List struct {
	Val  Expression
	Rest *List
}
// 函数类型
type Function func(*Env, []Expression) Expression
// 布尔类型
type Bool bool
// 整数
type Integer int64
// 浮点数
type Float float64

// 环境,包含父环境的引用及当前环境的符号表
type Env struct {
	parent *Env
	scope  map[string]Expression
}
```

我们定义的基本接口`Expression`，所有lis.go的类型都需要实现该接口，包括了：

* Symbol 符号
* Integer 整数
* Float 浮点数
* Bool 布尔值
* List 列表
* Function 函数

此外，我们还定义了环境 `Env`。或者叫作用域，程序运行时的符号查找都需要依赖于所处的环境，比如同一个符号 `a`，在不同的环境中，很可能引用了不同的值。

每个符号的解释，都需要优先查找当前环境，如果找不到则向上到父环境查找，直至根环境。这也很好理解，其实就是一个变量是局部变量还是全局变量的区别。

## Parsing: parse, tokenize and read_from_tokens

解析的过程通常分为两步：

* 词法解析，逐个字符读取代码文件，将字符串流解析为「词」的流，也叫 tokenize
* 语法解析，对 token 流进行语义分析，生成 AST

词法分析有很多现成的工具，这里我们使用最简单的一种: golang的 `strings.Split`

```go
func tokenize(s string) *TokenStream {
	s = strings.ReplaceAll(s, "(", " ( ")
	s = strings.ReplaceAll(s, ")", " ) ")
	return &TokenStream{tokens: strings.Split(s, " ")}
}
```

`parse` 函数接受代码字符串作为输入,调用`tokenize` 得到 token 流, 然后调用 `read_from_tokens` 将词流组织成抽象语法树。

`read_from_tokens` 遇到 `(` 则开始一个列表的解析,直至遇到列表结束符`)`;如果其他 case 则作为原子解析。

```go
// Read an expression from a sequence of tokens.
func read_from_tokens(tokens *TokenStream) Expression {
	if tokens.Empty() {
		panic("unexpected EOF while reading")
	}
	token := tokens.Pop()
	if "(" == token {
		l := &List{}
		for tokens.Peek() != ")" {
			l.Append(read_from_tokens(tokens))
		}
		tokens.Pop() // drop ')'
		return l
	} else if ")" == token {
		panic("unexpected )")
	} else {
		return atom(token)
	}
}

// Numbers become numbers; Booleans become booleans; any other token is a symbol.
func atom(token string) Expression {
	if val, err := strconv.ParseInt(token, 10, 64); err == nil && !strings.Contains(token, ".") {
		return Integer(val)
	} else if fval, err := strconv.ParseFloat(token, 64); err == nil {
		return Float(fval)
	} else if token == `true` || token == `false` {
		return Bool(token == `true`)
	} else {
		return Symbol(token)
	}
}
```

OK, 我们的 `parse` 函数已经可以运行了:

```go
>>> program = "(define r 10) (* pi (* r r))"

>>> parse(program)
['define', 'r', 10], ['*', 'pi', ['*', 'r', 'r']]
```

## 基础环境

在进入下一步之前，我们需要为代码准备好执行环境。

```go
func baseEnv() *Env {
	env := NewEnv(nil)
	env.scope["+"] = Function(plus)
	env.scope["-"] = Function(minus)
	env.scope["*"] = Function(multiple)
	env.scope["/"] = Function(divide)
	env.scope[">"] = Function(gt)
	env.scope["<"] = Function(lt)
	env.scope["=="] = Function(eq)
	return env
}
```

如前文所述，环境是符号解释的核心组件。在我们的基础环境里，已经定义好了加减乘除等几个基本操作函数，当然，你也可以提前定义好一些全局变量，任何 lis.go 支持的表达式都可以根据需求预置到环境中。

函数的实现也非常简单，以加法为例，其实就是调用了 golang 自己的加法操作符进行计算而已。

```go
func plus(env *Env, exprs []Expression) Expression {
	if isFloat(exprs[0]) || isFloat(exprs[1]) {
		return Float(toFloat(exprs[0]) + toFloat(exprs[1]))
	}
	return Integer(toInt(exprs[0]) + toInt(exprs[1]))
}
```

## Evaluation: eval


我们将根据之前的需求，实现该表中的能力:

| Expression | Syntax | Semantics and Example |
|------------| -------| ----------------------|
| 符号 | symbol | 一个符号通常引用了一个值，如 (define r 10) 表示符号 r 引用了值 10 | 
| 字面量| number | 比如数字 12 |
| 条件分支| (if test conseq alt) | 如果 test 为 true，则返回 conseq，否则返回 alt |
| 变量绑定| (define symbol expr) | 定义一个符号 symbol,且将其值绑定为 expr |
| 函数调用 | (proc arg ...) | 如果 proc 是关键字，如 if，则执行分支逻辑，否则寻找对应函数进行调用|

下面的代码即 `eval` 的实现:

```go
func eval(x Expression, env *Env) Expression {
	switch val := x.(type) {
	case Symbol:
		// variable reference
		return env.Find(val)[val.Sexpr()]
	case *List:
		return evalList(val, env)
	default:
		// constant literal
		return x
	}
}
```

如果是符号，则从环境中查找其引用的值，如果是列表则调用`evalList`对列表求值，如果是其他字面量，则直接返回字面量本身。

```go
func evalList(x *List, env *Env) Expression {
	name := string(x.Val.(Symbol))
	switch name {
	case "if":
		// (if test conseq alt)
		test, conseq, alt := x.Rest.Val, x.Rest.Rest.Val, x.Rest.Rest.Rest.Val
		if res := eval(test, env); res.(Bool) {
			return eval(conseq, env)
		} else {
			return eval(alt, env)
		}
	case "define":
		// (define var exp)
		vvar, expr := x.Rest.Val, x.Rest.Rest.Val
		env.scope[vvar.Sexpr()] = eval(expr, env)
		return env.scope[vvar.Sexpr()]
	case "set!":
		// (set! var exp)
		vvar, expr := x.Rest.Val, x.Rest.Rest.Val
		env.Find(vvar.(Symbol))[vvar.Sexpr()] = expr
		return expr
	default:
		// (function arg...)
		proc := eval(x.Val, env)
		var args []Expression
		for ptr := x.Rest; ptr.Val != nil; {
			args = append(args, eval(ptr.Val, env))
			ptr = ptr.Rest
		}
		return proc.(Function)(NewEnv(env), args)
	}
}
```

`evalList` 如果发现第一个符号是 `if` 等关键字，则执行对应逻辑，如果是函数调用，则调用对应的函数即可。

## Interaction: A REPL

为了使用我们的计算器，我们实现了一个简单的 REPL.

> REPL: Read Eval Print Loop

逐行读入代码字符串，然后计算结果并打印到标准输出。

```go
func repl() {
	line := liner.NewLiner()
	defer line.Close()

	line.SetCtrlCAborts(true)

	env := baseEnv()
	for {
		if sentence, err := line.Prompt("lis.go> "); err == nil {
			val := eval(parse(sentence), env)
			fmt.Println(val.Sexpr())
		} else {
			return
		}
	}
}
```


# 完整代码

完整的代码可以参考: [lis.go](https://github.com/qjpcpu/lis.go)

# 应用到生产环境?

`lis.go` 只是帮助学习实现解释器的简单玩具，如果想要应用于生产环境，可以使用 [glisp](https://github.com/qjpcpu/glisp)，其完整文档参考 [glisp-wiki](https://github.com/qjpcpu/glisp/wiki).
