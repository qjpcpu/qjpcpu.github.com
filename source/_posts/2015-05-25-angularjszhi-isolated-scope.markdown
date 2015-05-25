---
layout: post
title: "AngularJs之Isolated Scope"
date: 2015-05-25 14:12:42 +0800
comments: true
categories:  angularjs
---

### 分离式scope（Isolated Scope）
在angularjs指令中问什么需要使用分离式的scope,主要是为了分离指令和执行所在的"环境",这个环境其实就是指controller的scope和指令自身的scope,使用分离式scope达到隔离各自scope变量，避免变量污染，从而最大程度上达到指令的重用。

> 注意，下面的示例为了突出重点，使用CoffeeScript展示代码

```coffeescript script.coffee
angular.module('docsIsolateScopeDirective', []).controller('Controller', ['$scope',($scope) ->
  $scope.naomi =
    name: 'Naomi'
    address: '1600 Amphitheatre'
  $scope.igor =
    name: 'Igor'
    address: '123 Somewhere'
]).directive 'myCustomer', ->
  restrict: 'E'
  scope: customerInfo: '=info'
  template: 'Name: {{customerInfo.name}} Address: {{customerInfo.address}}'
```

```html index.html
<div ng-controller="Controller">
  <my-customer info="naomi"></my-customer>
  <hr>
  <my-customer info="igor"></my-customer>
</div>
```

```text 输出为
Name: Naomi Address: 1600 Amphitheatre Name: Igor Address: 123 Somewhere
```

由输出可以看出，指令`my-customer`中的`info`属性被分别绑定到了外部scope的两个变量`naomi`和`igor`，虽然是同一指令，但相互之间没有干扰或污染。这样`my-customer`指令可以非常漂亮的被重用。

其实，如果不需要特意在指令间共享scope，最好都使用分离式scope来写指令。

另外，指令内属性名如果和绑定的外部属性相同，可以采用简写模式，如这里`my-customer`的`info`属性映射到内部也用`info`引用的化:

```coffeescript script.coffee
directive 'myCustomer', ->
  restrict: 'E'
  scope: info: '='
  template: 'Name: {{customerInfo.name}} Address: {{customerInfo.address}}'
```

<!--more-->

### @单向绑定
对于仅仅需要在指令中反应外部scope变量变化的情况下，可以仅使用单向绑定，将controller的变量映射到指令中，一旦在controller中修改变量，指令中可以立即看到变化，然而反过来则不可，即外部scope中看不到指令内部对变量的修改。

```coffeescript script.coffee
.directive 'myDirective, ->
  scope: attributeFoo: '@' 
```

```html index.html
<my-component attribute-foo="{{foo}}"></my-component>
```

即，在控制器里修改foo，在`my-directive`中可以感知到。通常单向绑定对于取字符串值很常见，所以这里的html中使用双花括号插值。因此，单向绑定的官方名称其实是叫属性绑定。

### =双向绑定
看名称就知道用途了，双向绑定使用`=`定义，直接看例子:

```coffeescript script.coffee
.directive 'myDirective, ->
  scope: bindingFoo: '=' 
```

### &表达式绑定
或者换个更human的名称，函数绑定，如果需要在指令内调用controler的函数，这就是说我们可以在指令内部定义接口，controller定义具体实现，这样指令就能够变得非常灵活，用在分离式scope中，既避免了变量污染又达到了灵活性，太cool了。

```coffeescript my-directive.coffee
.directive 'myDirective, ->
  scope: myHandler: '&'
  template: '<button type="button" ng-click="myHandler({$count: 123})"></button>'
```

```coffeescript my-controller.coffee
.controller 'MyCtrl', ['$scope',($scope) ->
    $scope.getCounts = (countNum) -> console.log "Button click count: #{countNum}"
]
```

```html index.html
<my-directive my-handler="getCounts($count)"></my-directive>
```

#### 非常重要:函数传参
对于无参函数的绑定，没什么好说的。但对应上例中的情况，需要把参数从指令中传到外部函数，则需要注意了。

* 参数必须是hash类型的json对象，即参数是k-v类型的对象，如示例中的`{$count: 123}`
* html中使用指令的地方函数的参数必须和指令中函数传递的参数的key一一对应，即指令中传递的参数的key是`$count`，那么html中指令绑定的函数接受的参数必须是`$count`，否则无法接受正确的参数。但是在controller里的函数参数名不必和他们保持一致。

