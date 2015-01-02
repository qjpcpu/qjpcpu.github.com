---
layout: post
title: "angularJS路由框架ui-router"
date: 2014-12-29 17:32:53 +0800
comments: true
categories:  angularjs
---

# 简介
[AngularUI Router](https://github.com/angular-ui/ui-router)是AngularJS的路由框架，和默认的`$route`不同，它将所有路由包装成可划分层级的状态机状态,路由路径在ui-router中不是必须的。由于ui-router的路由状态机是分层级的，所以使用ui-router可以非常方便地创建包含多个嵌入的子模板。

<!-- more -->

# Demo
直接使用`ui-router`的方式可以参考其github文档，这里以yeoman为例简单展示下ui-router的使用。

在`bower.json`中加入ui-router依赖包,然后`bower install`执行安装

```json bower.json
{
  "name": "learn-angular",
  "version": "0.0.0",
  "dependencies": {
    /*省略其他*/ 
    "angular-ui-router": "^0.2.13"
  },
 /*省略其他*/ 
}
```

在`index.html`中添加引用：

```html app/index.html
<script src="bower_components/angular-ui-router/release/angular-ui-router.js"></script>
```
在app.coffee中设置路由：

```coffeescript  app/scripts/app.coffee
'use strict'

angular
  .module('learnAngularApp', [
    'ui.router'    # 添加模块依赖
  ])
  .run ['$rootScope', '$state', '$stateParams', ($rootScope,   $state,   $stateParams) ->
    $rootScope.$state = $state
    $rootScope.$stateParams = $stateParams
    ]
  .config ($stateProvider,$urlRouterProvider) ->
    $urlRouterProvider.otherwise "/"
    $stateProvider
      .state 'home',
        url: '/'                      # 可见默认路由状态是home
        templateUrl: 'views/home.html'
      .state 'state1',
        url: '/state1'
        templateUrl: 'views/state1.html'
      .state 'state1.list',
        url: '/list'
        templateUrl: 'views/state1.list.html'
        controller: ($scope) ->
          $scope.items = ["A", "List", "Of", "Items"]
      .state 'state2',
        url: '/state2'
        templateUrl: 'views/state2.html'
      .state 'state2.list',
        url: '/list'
        templateUrl: 'views/state2.list.html'
        controller: ($scope) ->
          $scope.things = ["A", "Set", "Of", "Things"]
```

ui-router最重要的三个服务`$state`,`$stateProvider`,`$urlRouterProvider`。在`$stateProvider`上配置所有的状态，state方法的第一个参数是状态名，第二个参数是一个hash对象，里面可以配置`url`,`templateUrl`,`controller`等。

注意其中类似`state1.list`和`state1`的状态，`state1.list`是`state1`的子状态，所以触发`state1.list`的url是父子状态的联合，即`/state1`+`/list` => `/state1/list`,所以当浏览器导航到`/state1/list`（或手动触发`$state.go()`）时，`state1.list.html`才被插入父模板渲染。

下图非常清晰反映了ui-router的渲染逻辑：

* 绿色 = 初始状态
* 黄色 = 即时渲染
* 蓝色 = 最终状态

![渲染逻辑](https://camo.githubusercontent.com/15b1f1780e3a88cc1d6e0055dda298279d66fad7/68747470733a2f2f7261772e6769746875622e636f6d2f77696b692f616e67756c61722d75692f75692d726f757465722f5374617465476f4578616d706c65732e706e67)

主模板index.html:

```html app/index.html
<div>
    <ul>
      <li ui-sref-active="active"><a ui-sref="home">home</a></li>
      <li ui-sref-active="active" ><a ui-sref="state1">state1</a></li>
      <li ui-sref-active="active"><a ui-sref="state2">state2</a></li>
    </ul>
</div>
<div ui-view></div>
```

这里出现了两个ui-router的指令，`ui-sref`类似于angularjs的`ng-href`，只不过后面指定的是路由状态。

另一个指令就是`ui-view`，ui-router根据激活的状态向该指令中插入子模板。ui-router插入模板的规则是：`ui-router会将激活状态的模板插入父状态模板的ui-view处`。home状态是根状态，所以`app/index.html`的`ui-view`中插入的就是home状态的模板片段`app/views/home.html`。

其他模板：

```html
<!-- app/views/state1.html -->
<h1>State 1</h1>
<hr/>
<a ui-sref="state1.list">Show List</a>
<div ui-view></div>
<!-- app/views/state1.list.html -->
<h3>List of State 1 Items</h3>
<ul>
  <li ng-repeat="item in items">{{ item }}</li>
</ul>
<!-- app/views/state2.html -->
<h1>State 2</h1>
<hr/>
<a ui-sref="state2.list">Show List</a>
<div ui-view></div>
<!-- app/views/state2.list.html -->
<h3>List of State 2 Things</h3>
<ul>
  <li ng-repeat="thing in things">{{ thing }}</li>
</ul>
```

由上面的规则可以同理推出，当url为`/state1/list`时，会渲染主模板`state1.html`，并且会将子模板`state1.list.html`嵌入`state1.html`的`ui-view`中一起渲染出来。cool，路由渲染的灵活性非常高！

另外还有一个常用指令`ui-sref-active="classname"`,它通常和`ui-sref`一起使用，含义是当前状态被激活则会在所属html标签上class属性添加classname,如果不再是激活状态则去除classname。

另外，ui-router还支持多模板：

```html app/views/index.html
<body>
    <div ui-view="viewA"></div>
    <div ui-view="viewB"></div>
    <!-- Also a way to navigate -->
    <a ui-sref="route1">Route 1</a>
    <a ui-sref="route2">Route 2</a>
</body>
```

```coffeescript app/scripts/app.coffee
myApp.config ($stateProvider) ->
  $stateProvider.state("index",
    url: ""
    views:
      viewA:
        template: "index.viewA"
      viewB:
        template: "index.viewB"
  ).state("route1",
    url: "/route1"
    views:
      viewA:
        template: "route1.viewA"
      viewB:
        template: "route1.viewB"
  ).state "route2",
    url: "/route2"
    views:
      viewA:
        template: "route2.viewA"
      viewB:
        template: "route2.viewB"
```
