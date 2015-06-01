---
layout: post
title: "分享你的Angular指令"
date: 2015-05-27 17:47:56 +0800
comments: true
categories: angularjs 
---

### Angular directive on bower
用Angular做web开发不但听起来是非常炫酷的事情，而且从我实际的开发体验来看，它确实是极大减轻了开发者的痛苦。我可以把精力都花在组织业务逻辑，创建更为流畅和漂亮的UI上，而完全不用去反复沦陷在事件绑定数据更新这些无趣的事情上。此外，angular框架本身依照设计模式上定义出了一套MVC漂亮的实现,了解其controller,server,directive后，写出大型web app已经不是难事了。

Angular中最漂亮的两个组件是service和directive，简单说来，service是逻辑代码的抽象和封装，它将应用中重复使用的逻辑代码抽象为公共服务，便于打造瘦controller；而directive则是对UI组件的抽象，其对directive的封装和接口设计简直刷新了我对前端的认识。

这里我就不准备详细介绍怎么写指令了，google的文档和我之前的博客都可供参考，这里说一下，如果你写出来非常cool的指令，怎么分享给大家呢？答案是bower。

<!--more-->

### Bower
[Bower](http://bower.io/)是一个js的客户端管理工具，可以称之为客户端的npm，其作者是twitter的几个家伙([@fat](https://github.com/fat),[@maccman](https://github.com/maccman))。根据你配置的`bower.json`文件，Bower可以自动查找、下载和安装js库，极大节约开发时间。

#### 简单介绍

```bash 安装使用
npm install -g bower
# registered package
bower install jquery
# GitHub shorthand
bower install desandro/masonry
# Git endpoint
bower install git://github.com/user/package.git
# URL
bower install http://example.com/script.js
```
### 创建一个基于bower的angular指令angular-dropzone
[Dropzone](http://www.dropzonejs.com/)是一个漂亮的文件上传组件，下面就演示怎么把它集成为一个angular指令并分享到github。

#### 1.创建指令工程
```bash
mkdir angular-dropzone && cd $_
touch angular-dropzone.js #  写入指令实现
bower init # 初始化bower工程
```
回答完一系列问题后，生成的`bower.json`文件应该类似：

```
{
  name: 'angular-dropzone',
  main: 'angular-dropzone.js',
  version: '0.0.0',
  authors: [
    'qujianping <qjpcpu@gmail.com>'
  ],
  description: 'dropzone for angular',
  keywords: [
    'angular',
    'dropzone'
  ],
  license: 'MIT',
  ignore: [
    '**/.*',
    'node_modules',
    'bower_components',
    'test',
    'tests'
  ],
  dependencies: {
    angular: '~1.3.0',
    dropzone: '~4.0.1'
  }
}
```

#### 2.编辑指令代码
现在开始编写指令的实现。指令代码最好遵守一定命名规范，如：以github名称作为命名空间。
```javascript angular-dropzone.js
angular.module('qjpcpu.angular-dropzone', []).
  directive('qjpDropzone', function () {
    // implementation goes here
  });
```
具体代码实现可以参考[angular-dropzone](https://github.com/qjpcpu/angular-dropzone)

#### 3.发布指令
编写完成后，就可以推送到github。

```bash
git init .
git add bower.json angular-dropzone.js
git commit -m 'v0.0.0'
git tag v0.0.0
git remote add origin git@github.com:qjpcpu/angular-dropzone.git
git push -u origin master
```
注意，bower使用git的tag确定版本号。

#### 4.在你的应用中使用该指令
现在可以拉取使用你的angular指令了：
```
bower install qjpcpu/angular-dropzone
```

在`index.html`文件添加加载的文件:

```html index.html
<link rel="stylesheet" href="bower_components/dropzone/dist/dropzone.css">
<script src="bower_components/dropzone/dist/dropzone.js"></script>
<script src="bower_components/angular-dropzone/angular-dropzone.js"></script>
```

需要添加模块依赖:
```coffeescript app.coffee
app = angular.module("my-app", [
  'qjpcpu.angular-dropzone'
])
```
这样在html片段里就可以使用指令了,关于该指令具体参数参考[angular-dropzone](https://github.com/qjpcpu/angular-dropzone):

```html p.html
<div qjp-dropzone class="droppable-area" url="'/url/to-upload'">
	Drop file here
</div>
```
