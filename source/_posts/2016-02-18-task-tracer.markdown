---
layout: post
title: "task tracer -- 实时任务追踪系统"
date: 2016-02-18 14:43:27 +0800
comments: true
categories: linux
---

## 产生背景

**Task Tracer(以下简称tt)**的产生原因其实是为了解决一个用户体验的缺憾。由于在生产环境中，我们一直使用salt-stack作为任务的发布和执行机构，然而salt使用的Pub/Sub这种模式下有一个遗留缺陷: 就是任务一旦发出，直到它执行结束退出，任务的发起者无法知道任务当前的执行状态,唯一能做的仅仅能够判断该任务是否在running,而不能实时获取其进程输出；其次，当该salt任务执行完成后，需要独立获取其任务标准输出和进程退出状态(exit code)，无法一次性获取其输出和退出状态。salt社区也意识到这个问题，在逐步开发VT模块以求解决，不过这个特性截止到目前仍在实验阶段。

所以，为了消除salt任务执行阶段的黑洞焦虑，我决定开发tt。 虽然tt是为了解决salt的一个问题，但在开发时，我决定将其和salt分离开来，使得tt其实是能够解决这样一类问题: **如果需要实时获取命令执行输出，就可以将命令包裹到tt中执行,从而利用tt Server实时获取其执行输出及结果**

<!-- more -->

![tt preview](https://raw.githubusercontent.com/qjpcpu/task-tracer-server/master/snapshots/tt-preview.png)

## 工作原理

tt其实是一个shell命令包裹器，它将要执行的命令以子进程的方式执行起来，实时地将该子进程的输出发送到tt Server，这样用户(api client)就能够从tt Server实时读取到该进程的输出；使用到的技术其实也很简单，就是nodejs+socket.io。
![tt](https://raw.githubusercontent.com/qjpcpu/task-tracer-server/master/snapshots/data-flow.png)

从这张原理图可以看到，tt的数据流是单向的，也就是说这里的任务发起需要第三方来做，比如salt-stack甚至手动的shell登录后发起。当任务发起后，tt client会吐出一个输出结果查看的url，使用你的浏览器访问该url就可以实时查看任务的输出，另外，相同任务名下执行的所有tt client都会将输出发布出来，均可以查看。

另外，tt是一个实时输出查看跟踪系统，所以不会持久化任务的输出。

## Try our live demo

### 1. 配置客户端

根据你的系统类型(osx/linux)下载客户端可执行文件tt

```
# for osx
wget https://raw.githubusercontent.com/qjpcpu/task-tracer-client/master/dist/tt.darwin -O tt
# for linux
wget https://raw.githubusercontent.com/qjpcpu/task-tracer-client/master/dist/tt.linux -O tt
```

客户端会读取配置文件`$HOME/.tt.conf`，将其内容配置为:

```
id = natasha
token = eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0eXBlIjoiY2xpZW50X3Rva2VuIiwibnMiOiJ0ZXN0IiwiaWF0IjoxNDU1NzgwNDU0LCJleHAiOjE0ODczMzgwNTR9.hk96PzocFTSGogl1evyWa4UGjDpQ4nAWppIMCl6lnlo
url = http://tt.single-bit.org
```

同样的方法再配置一台客户端，注意其配置文件中id和另一台不同（可以根据需要配置任意多台客户端,注意其配置文件中id需要各不相同）。

```
id = tanya
token = eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0eXBlIjoiY2xpZW50X3Rva2VuIiwibnMiOiJ0ZXN0IiwiaWF0IjoxNDU1NzgwNDU0LCJleHAiOjE0ODczMzgwNTR9.hk96PzocFTSGogl1evyWa4UGjDpQ4nAWppIMCl6lnlo
url = http://tt.single-bit.org
```

### 2. 访问任务追踪页面

打开浏览器访问[tt Server live demo](http://tt.single-bit.org/?accessToken=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0eXBlIjoiYnJvd3Nlcl90b2tlbiIsIm5zIjoidGVzdCIsImlhdCI6MTQ1NTc4MDQ1NCwiZXhwIjoxNDg3MzM4MDU0fQ.AuhXIVNxk5LYoamU2ziSBqvn0tEqyrszAvsCom3OmgI)

![live demo index page](https://raw.githubusercontent.com/qjpcpu/task-tracer-server/master/snapshots/live-demo-index.png)

填入我们需要追踪的任务名称，如: **demo**并确定，进入到任务监听状态。

### 3. 执行任务

在配置好的两台客户端上同时执行命令:

```
tt -n demo 'echo "from `head -1 ~/.tt.conf`";sleep 2;echo "sleep for a while";sleep 5;echo done'
```

在浏览器上可以看到实时输出: 在`tanya`和`natasha`分别输出各自的id，然后等待一会儿后进程执行结束.

![live demo output page](https://raw.githubusercontent.com/qjpcpu/task-tracer-server/master/snapshots/live-demo-output.png)

你也可以在执行过程中在某个客户端上执行`kill`命令或`Ctrl+C`终止进程，并查看浏览器实时反馈的结果。


## As a sevice -- 搭建自己的tt Server

如果tt仅仅是作为一个web页面查看机器上的进程输出，那其实也没多大存在意义，关键是对于一个devops来说，它需要能够比较容易地嵌入你的系统工具里。

### 1. 系统接口

ttServer对外提供了若干[socket.io](http://socket.io/)事件接口，基于你的需求，可以非常容易地接入到你自己的系统中，这样一来，怎样在UI上展示就完全取决于自己的实现。至于socket.io也有很多语言已经实现了该规范，所以使用起来应该也很简单。

详细接口定义及实现方式请查看[tt Server github文档](https://github.com/qjpcpu/task-tracer-server)

### 2. 客户端安装配置

tt的客户端安装配置非常简单，仅仅包含一个可执行文件tt和一份简单的ini格式的配置文件,令人愉悦的是该客户端没有环境依赖，不需要安装node等执行环境。

如果下载的二进制文件无法执行，请从源码编译。

具体的客户端安装配置可以查看[tt Client github文档](https://github.com/qjpcpu/task-tracer-client)

## 相关系统: log.io

[log.io](http://logio.org/)是一个实时日志监控系统，其系统架构和实现方式都和tt非常相似。不过其应用场景是实时的日志采集监控，另外，logio的客户端有node环境依赖，个人觉得有点部署不完美。

![log.io](http://logio.org/screenshot3.png)

## 附录: github地址

[tt Server](https://github.com/qjpcpu/task-tracer-server)
[tt Client](https://github.com/qjpcpu/task-tracer-client)
