---
layout: post
title: "新建angular项目"
date: 2014-11-25 10:54:31 +0800
comments: true
categories: angularjs
---

## 需要的工具

* [bower](http://bower.io/) 前端包管理器
* [grunt](http://gruntjs.com/) javascript的makefile工具
* [yeoman](http://yeoman.io/)  webapp的流行脚手架
* [karma](http://karma-runner.github.io/0.12/index.html) 测试套件

这里我使用了yeoman的一个angularJS的生成器[yo](https://github.com/yeoman/generator-angular)，方便生成需要的全部零部件

<!-- more -->

## 新建工程

我们要建立的angularjs工程的项目名称叫`MyAngularApp`

```bash
mkdir MyAngularApp
cd MyAngularApp
# 这里我习惯用coffee来写代码，如果直接用javascript可以去掉后面的参数--coffee
yo angular --coffee
```

生成的目录结构如下：

```
MyAngularApp
├── Gruntfile.js
├── README.md
├── app
│   ├── 404.html
│   ├── favicon.ico
│   ├── images
│   ├── index.html
│   ├── robots.txt
│   ├── scripts
│   ├── styles
│   └── views
├── bower.json
├── bower_components
│   ├── angular
│   ├── angular-animate
│   └── ......
├── node_modules
│   ├── coffee-script
│   └── ......
├── package.json
└── test
    ├── karma.conf.coffee
    └── spec
```

其中，`Gruntfile.js`是grunt的makefile文件，里面定义了各种编译任务，如常用的`grunt serve`和`grunt build`。

`app`目录是主要的工作目录，下面的`scripts`目录放置所有的controller，`styles`放置各种css文件，`views`放置视图模板；也可以在`app`下防止自己的资源文件夹如`vendor`目录，放置第三方库。

`bower.json`中定义了需要安装的库，功能类似于ruby的Gemfile文件，在工程根目录执行`bower install`安装依赖。所有的依赖库都会被安装到`bower_components`目录中。

`node_modules`是项目工具如coffee或者grunt的依赖工具。

`package.json`是grunt的依赖工具。

`test`是测试文件所在。

## index.html

yo的常用操作可以参考其github文档。这里需要补充说一下的是`app/index.html`文件，该文件是angular项目的起始文件。注意其中类似下面这样的语句：

```html
<!-- build:css({.tmp,app}) styles/main.css -->
<link rel="stylesheet" href="styles/main.css">
<!-- endbuild -->

<!-- build:js(.) scripts/vendor.js -->
<!-- bower:js -->
<script src="bower_components/angular/angular.js"></script>
<script src="bower_components/angular-animate/angular-animate.js"></script>
<script src="bower_components/angular-cookies/angular-cookies.js"></script>
<script src="bower_components/angular-resource/angular-resource.js"></script>
<script src="bower_components/angular-route/angular-route.js"></script>
<script src="bower_components/angular-sanitize/angular-sanitize.js"></script>
<script src="bower_components/angular-touch/angular-touch.js"></script>
<!-- endbower -->
<!-- endbuild -->
```

要注意的是`<!-- build:css(DIRECTORY) OUT_FILE -->`和`<!-- build:js(DIRECTORY) OUTFILE -->`，它们并不是普通的html注释，而是grunt的指令。

比如第一段，grunt会将`build:css`到`endbuild`之间的css文件找到，查找路径是`build:css(DIRECTORY)`中的目录加上`link`标签里的`href`指定的文件路径所在文件，即`.tmp/styles/main.css`和`app/styles/main.css`,然后grunt将它们合并压缩为一个css文件`styles/main.css`，这个文件被生成在输入目录，通常是`dist/styles/main.css`。

类似的，下面的js编译将当前目录`.`下指定的`bower_components`下的一些js合并压缩后变成`dist/scripts/vendor.js`。

所以，自己引入的一些第三方库怎么弄也就清楚了：

```html
<!-- build:css(app) assets/css/vendor.css -->
<link href="assets/css/animate.min.css" rel="stylesheet" />
<link href="assets/plugins/gritter/css/jquery.gritter.css" rel="stylesheet" />
<!-- endbuild -->
```

## grunt

最后说一下grunt的任务，如果在app目录有个`assets/img`目录，里面放了一些图片，希望执行`grunt build`后将这些资源复制到输出目录，那么可以对`Gruntfile.js`做简单修改，如：

```javascript
    // Copies remaining files to places other tasks can use
    copy: {
      dist: {
        files: [{
          expand: true,
          dot: true,
          cwd: '<%= yeoman.app %>',
          dest: '<%= yeoman.dist %>',
          src: [
            '*.{ico,png,txt}',
            '.htaccess',
            '*.html',
            'views/{,*/}*.html',
            'images/{,*/}*.{webp}',
	        'assets/{,img/*.*,fonts/*.*}',   //这里添加了一行,也可以直接复制整个文件夹 'assets/**'
            'fonts/{,*/}*.*'
          ]
        }
    },
```
