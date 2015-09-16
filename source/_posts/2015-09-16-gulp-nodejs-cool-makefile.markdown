---
layout: post
title: "gulp js的构建工具"
date: 2015-09-16 21:56:17 +0800
comments: true
categories: nodejs
---

### 0. 简介
gulp是javascript世界的构建工具，它并不是js世界第一个构建工具，但由于它小而快的特点，一出现就快速赶超它的前辈grunt，在npm的下载榜上一直高居前列。

<!-- more -->
![gulp logo](https://raw.githubusercontent.com/gulpjs/artwork/master/gulp-2x.png)

### 1. gulp的特性
**`小`**

gulp的第一个特点应该是小，不仅仅是源码小，更重要的是gulp编写的出的构建代码非常短小明了。这是因为gulp基本上完全是基于流式的构建处理，可以理解为由源码文件流经过一系列的中间加工处理直接将结果灌入到输出文件，没有了中间的临时文件读写，自然就减少了处理代码，出来的构建workflow同样也就十分清理简捷。

gulp构建流程的小固然有使用了流式处理的原因，但更重要的一种设计思路的不同。这里我想聊一下工程上的设计理念，通常我们设计程序的时候，遵守`配置优于代码`的原则。就是说，一些程序依赖的外置参数，尽量不要硬编码进代码文件里，而是将这些参数放在配置文件中。遵循这条原则可以极大增加工程的可维护性，比如java语言的某些著名框架就严格践行了这条原则，所以工程中就可能出现描述工程信息的各种xml配置文件。然后很多时候宣扬这条规律的书籍都没有将他的缺点，虽然缺点和优点相比有点微不足道，那就是一旦大量抽离程序的配置参数，将导致配置的碎片化，反面教材仍然是java框架里的xml配置泛滥。

所以后来的编程框架如rails开始强调`约定优于配置`的概念，就是如果大家经验约定这样做(放置配置的方式，命名的方式，搜索的方式等），那么程序工程里就不必显式声明这些规则，即不必要用一大堆配置文件去描述我们大家都约定遵守的东西。这样出来的结果工程上非常干净同时也满足了约定内高维护性。

那么在这里为什么要说这个呢，因为grunt其实可以说是一个基于`配置由于代码`的构建工具，而且很多其他编程语言的构建工具都是基于这个理念的。这类构建工具在执行大工程的构建时，配置的碎片化非常严重，为了描述构建需要在构建代码里编写大量的元信息片段，甚至于需要分立诸多构建小文件来描述子构建单元，那么维护构建流程本身也变成一件令人头疼的事情。

而gulp可以说某种程度上的回归，将更多的东西又返回到了原始的地方-------代码。gulp的构建文件里配置信息非常少，一个构建task包含的所有信息都在这个task里，你不需要跳到其他文件里查阅这个task的配置信息。是的，程序员喜欢代码，把构建所有的东西都在task这块代码里完成，这样的构建流程自然就很清晰了。所以，gulp非常适合中小型程序的构建，我私自揣度这也是gulp快速流行起来的原因。

**`快`**

gulp的快主要是因为它的核心是`流`,从源文件的读取到构建结束，整个加工过程都在内存流里完成，上一道工序和下一道加工工序间完全是流与流之间的管道连接，类似shell管道命令的流式操作，免去了大量中间文件的读写，少了文件io，自然快了很多。不过我并没有专门对这个做过benchmark，直观的感受是我重构某个包含数百个coffee文件的构建流程时，从grunt迁移为gulp后整个构建流程节省了大概一半的时间。

**`简单`**

在阅读了gulp的一些资料后，我本来打算花一个下午的时间来学习的，结果10分钟左右就读完了gulp的文档，因为它实在太简单了，总共只有**4个**API.

### 2. gulp入门

对于gulp的基础，我不打算在这里讲，因为它的[官方文档](https://github.com/gulpjs/gulp/tree/master/docs)非常简单易读，如果想读中文，这里也有[gulp中文文档](https://github.com/lisposter/gulp-docs-zh-cn)。花个10分钟读一下，你就可以向身边的小伙伴炫耀： Hi，让我给你展示下一种很cool的构建工具。

### 3. gulp流

`流`是gulp重中之重的概念，理解了流才可以玩转gulp。可以看下[nodejs流](https://github.com/substack/stream-handbook)深入理解下nodejs流的概念。这里仅简单介绍下gulp中广泛使用的`pipe()`函数。

`src.pipe(dest)`函数是nodejs的流的一个函数，它的作用非常简单，就是将流进行管道连接，将src可读流和dest可写流连接起来，使得数据从src流入dest。

同时`src.pipe(dest)`的返回对象也是`dest`，所以在nodejs很容易看到这种链式编程风格。

```javascript
a.pipe(b).pipe(c).pipe(d)
```

这段代码等价于

```javascript
a.pipe(b);
b.pipe(c);
c.pipe(d);
```

这个操作和shell编程的管道非常相似: `a | b | c | d`

### 4. gulp任务的编写准则

gulp的核心是流，构建单元是一个个`task`，那么编写这些task的时候需要注意什么呢？

gulp的task做到了最大限度的并发，那么这些task间的同步就成了问题，怎么样判断一个task完成了以便于可以安全执行另一个依赖task呢,为了正确调度任务，gulp的task设计有三个原则:

```
1. 在任务定义的function中返回一个数据流，当该数据流的end事件触发时，任务结束
2. 在任务定义的function中返回一个promise对象，当该promise对象resolve时，任务结束
3. 在任务定义的function中传入callback变量，当callback()执行时，任务结束
```

当发现task没有按预期执行时，就需要仔细检查是否每个task都遵循了这3条规则。

此外，当需要写出一些高阶的gulp玩法时，不理解并执行这几条规则，就很难办到。另外，可以思考个额外的问题，为什么gulp的task需要有这三条规则? 根据这3条规则，是否都可以猜测出gulp的实现机制呢?

在这里我顺便申明我对学习新东西的一个观点，就是`seize the key`，学习一种新东西就要理解她的核心。有的人秉持一种观念是说，语言只是工具，学习了一种其他都差不多，当有切换需求要学习新语言or新工具，就草草将以前的经验套上去，完成任务后还以为学会了新语言。所以有时候会看到一些四不像的代码，比如长得像shell的ruby代码，长得像java的python代码，一脸C长相的golang...

那么，怎样一学习新东西就能抓住其核心呢，很简单，多想想`why`。实际操作起来就几点经验：

* 如果有作者对这个语言/工具的创作初衷的相关文章，一定要看！
* 看这个新东西是为了解决什么问题
* 这个语言解决的是什么问题，更重要的是解决的思路或方式是什么！
* 如果涉及新的概念或思路，一定要看足够多的文档直到理解这个概念
* 如果学习的是新语言，必须**理解**这个语言的**key feature**，了解语言的生态圈，语言的编码规范、构建工具、测试工具、包管理工具，该语言里著名的库/框架，这些框架的设计理念，如果有余力可以看下这些库/框架的源码，告诉自己用这种语言写出的代码也应该是这个水平

比如对于gulp:

* **创作初衷**: 看文档FAQ,作者twitter
* **需要解决的问题**: grunt复杂庞大的插件配置
* **解决思路**: nodejs流式处理=>什么是nodejs流=>解决什么问题，带来什么问题

方方面面的东西了解了之后，你就能真正把控你的新玩意儿，有时候你甚至能预测这个语言或工具的未来动向。

### 5. 常用gulp插件

关于gulp的插件，需要的时候去github上找一下基本都能找到，这里提几个可能是通用构建流程里很可能用到的。

#### [run-sequence](https://www.npmjs.com/package/run-sequence)

鉴于流程控制对javascript这种纯异步编程的重要性，gulp的异步任务控制需求同样强烈，run-sequence就是为了解决这个问题。

```javascript
var gulp = require('gulp');
var runSequence = require('run-sequence');
var clean = require('gulp-clean');
 
// This will run in this order: 
// * build-clean 
// * build-scripts and build-styles in parallel 
// * build-html 
// * Finally call the callback function 
gulp.task('build', function(callback) {
  runSequence('build-clean',
              ['build-scripts', 'build-styles'],
              'build-html',
              callback);
});
 
// configure build-clean, build-scripts, build-styles, build-html as you 
// wish, but make sure they either return a stream or handle the callback 
// Example: 
 
gulp.task('build-clean', function() {
    return gulp.src(BUILD_DIRECTORY).pipe(clean());
//  ^^^^^^ 
//   This is the key here, to make sure tasks run asynchronously! 
});
 
gulp.task('build-scripts', function() {
    return gulp.src(SCRIPTS_SRC).pipe(...)...
//  ^^^^^^ 
//   This is the key here, to make sure tasks run asynchronously! 
});
```

#### [del](https://www.npmjs.com/package/del)

删除文件，这是个再频繁不过的需求了。

```javascript
var del = require('del');
 
del(['tmp/*.js', '!tmp/unicorn.js']).then(function (paths) {
    console.log('Deleted files/folders:\n', paths.join('\n'));
});
```

主要，del函数返回的是一个promise对象。

#### [merge-stream](https://www.npmjs.com/package/merge-stream)

当一个task里有多条流时，怎么办? merge-stream就是为了解决流的合并问题的。

```javascript
var gulp = require('gulp');
var merge = require('merge-stream');

gulp.task('test', function() {
  var bootstrap = gulp.src('bootstrap/js/*.js')
    .pipe(gulp.dest('public/bootstrap'));

  var jquery = gulp.src('jquery.cookie/jquery.cookie.js')
    .pipe(gulp.dest('public/jquery'));

  return merge(bootstrap, jquery);
});
```

当`bootstrap`和`jquery`这两条流都完成时，合并后的流才算完成。

#### 用户代码

还有一种情况，如果task的流处理完成时，我希望执行一些用户代码，比如仅仅打印一些信息，这要怎么做呢? 使用task依赖固然可以完成，但是仅仅因为这个需求就增加一个`空`task是不是有点杀鸡用牛刀了，如果真正理解了nodejs流和gulp的task规则，其实也很好办:

```javascript
gulp.task('cli', ['coffee'], function(cb) {
  gulp.src('*.coffee').pipe(coffee()).pipe(gulp.dest('js/')).on('end', function() {
    doSomething();
    return cb();
  });
  return null;
});
```
注意task的返回值及task回调cb。

### 6. 结束

gulp是一个很cool的构建工具，学习她，在合适的时候使用她。

