---
layout: post
title: "创建递归菜单"
date: 2015-01-02 12:44:07 +0800
comments: true
categories:  angularjs
---

如果菜单的数据模型是这样的,在angularjs中怎样比较漂亮地递归渲染出所有菜单项呢？

```json
menuItems = [
  {
    "label": "level1",
    "link": "/A",
    "menuItems": [
      {
        "label": "level2",
        "link": "/A/a1"
      }
    ]
  },
  {
    "label": "level1",
    "link": "/B",
    "menuItems": [
      {
        "label": "level2",
        "link": "/B/b1"
      }
    ]
  }
]
```

<!-- more -->

## 需要的ng指令

### script

将`<script>`的内容加载到$templateCache,这样就能够在ngInclude, ngView或指令中使用。`<script>`的类型必须是`text/ng-template`，并用`id`指定id。如：

```html
<script type="text/ng-template" id="tpl-1">
  Content of the template.
</script>
```

### ngInit
在当前scope内重命名某属性

```html
<script>
  angular.module('initExample', [])
    .controller('ExampleController', ['$scope', function($scope) {
      $scope.list = [['a', 'b'], ['c', 'd']];
    }]);
</script>
<div ng-controller="ExampleController">
  <div ng-repeat="innerList in list" ng-init="outerIndex = $index">
    <div ng-repeat="value in innerList" ng-init="innerIndex = $index">
       <span class="example-init">list[ {{outerIndex}} ][ {{innerIndex}} ] = {{value}};</span>
    </div>
  </div>
</div>
```

输出：

    list[ 0 ][ 0 ] = a;
	list[ 0 ][ 1 ] = b;
	list[ 1 ][ 0 ] = c;
	list[ 1 ][ 1 ] = d; 

## 示例
下面的示例代码就利用这些指令，将递归的菜单分割成扁平的模板，避免html模板过深的层次。

```html
<script type="text/ng-template" id="menu-item-link-tpl">
    <span class="title">{{item.title}}</span>			
    <span ng-if="item.label">{{item.label.text}}</span>
</script>

<script type="text/ng-template" id="menu-items-tpl">
    <li ng-repeat="item in menuItems">
	<a href="#{{item.link}}" ng-include="'menu-item-link-tpl'"></a>
	<ul ng-if="item.menuItems.length" ng-init="subItems = item.menuItems" ng-include="'menu-items-recursive-tpl'"></ul>
    </li>
</script>

<script type="text/ng-template" id="menu-items-recursive-tpl">
    <li ng-repeat="item in subItems">
	<a href="#{{item.link}}" ng-include="'menu-item-link-tpl'"></a>
	<ul ng-if="item.menuItems.length" ng-init="subItems = item.menuItems" ng-include="'menu-items-recursive-tpl'"></ul>
    </li>
</script>

<ul ng-include="'menu-items-tpl'">
</ul>
```

