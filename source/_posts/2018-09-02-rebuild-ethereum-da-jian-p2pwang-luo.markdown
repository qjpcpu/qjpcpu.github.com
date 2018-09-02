---
layout: post
title: "[rebuild ethereum](一) 搭建p2p网络"
date: 2018-09-02 14:24:16 +0800
comments: true
categories: blockchain 
---

接触使用ethereum已经有大半年时间，一直觉得对以太坊了解无法更进一步。结合自己以前的经验, the most efficient way of learn something is to build one. 想要深入学习一样东西，最有效的方式就是自己弄脏手，从头搭建一个。

比如动手做linux from scratch来学习linux的五脏六腑，rebuild rails来学习rails，所以我想尝试做一个rebuild ethereum系列,来解构ethereum。

在该rebuild系列中，我将把视角定在构成区块链的大模块纬度,先从以太坊源码中抽离该模块,然后使用该模块编写一个可执行的程序，这样能够真实感受到这个模块的运行机制和使用方法；最终能产生"以太坊(区块链)不外乎就是这几个模块组装起来的"这种印象就达到我的目的的。

<!-- more -->


* 目录
{:toc}

# 前言

这是rebuild ethereum的第一篇,我将尝试抽离以太坊底层的p2p网络模块,搭建一个可执行的3节点的p2p网络。在这里，我不会深入介绍具体细节，其中涉及到技术细节读者可以直接查看ethereum源代码,也可以参考我之前关于以太坊p2p实现细节的几篇博客。

# 基本诉求

先来看看我们对于一个p2p网络模块的基本诉求:

* 接入网络的便利性,其实也可以表述成网络易于建立，有足够的内网穿透能力
* 具备节点发现和维护的能力
* 提供上层协议的拓展能力,以tcp类比,能做到在不清楚tcp的底层细节就能够开发出http协议

# 基于ethereum-p2p实现一个自定义协议的p2p网络

## foo-bar网络

我们实现的这个p2p网络叫foo-bar网络,她的功能很简单,接入网络后向新节点发一条`welcome`消息,然后再发一条`foo`,当节点收到后会回复一条`bar`消息.

定义foo-bar协议:

```go
type MessageType = uint64

// 消息类型必须从0开始递增
const (
	MT_HelloWorld MessageType = iota
	MT_FooBar
)

type Message string

func FooBarProtocol() p2p.Protocol {
	return p2p.Protocol{
		Name:    "FooBarProtocol",
		Version: 1,
		Length:  2,  // 有几种消息类型就是几
		Run:     msgHandler,
	}
}
```

要注意关于协议支持的消息类型的定义，具体原因和以太坊实现细节有关,具体可以查阅[p2p模块基础结构](http://qjpcpu.github.io/blog/2018/01/29/shen-ru-ethereumyuan-ma-p2pmo-kuai-ji-chu-jie-gou/)

实现foo-bar协议handler内容:

```go
func msgHandler(peer *p2p.Peer, ws p2p.MsgReadWriter) error {
	// send msg
	log.Infof("new peer connected:%v", peer.String())
	p2p.SendItems(ws, MT_HelloWorld, srv.NodeInfo().Name+":welcome "+peer.Name())
	p2p.SendItems(ws, MT_FooBar, "foo")
	for {
		msg, err := ws.ReadMsg()
		if err != nil {
			log.Warningf("peer %s disconnected", peer.Name())
			return err
		}

		var myMessage [1]Message
		err = msg.Decode(&myMessage)
		if err != nil {
			log.Errorf("decode msg err:%v", err)
			// handle decode error
			continue
		}

		log.Info("code:", msg.Code, "receiver at:", msg.ReceivedAt, "msg:", myMessage)
		switch myMessage[0] {
		case "foo":
			err := p2p.SendItems(ws, MT_FooBar, "bar")
			if err != nil {
				log.Errorf("send bar error:%v", err)
				return err
			}
		default:
			log.Info("recv:", myMessage)
		}
	}
}
```

## 启动网络

这里我们启动3个节点,对于测试网络结构及运转已经足够了.

首先编译二进制程序:

```
cd ethereum-from-scratch/p2p-network && go build
```

启动3个节点

```
# 启动节点1
./start_node1.sh

# 打开新终端窗口启动节点2
./start_node2.sh

# 打开新终端窗口启动节点3
./start_node3.sh
```

![foo-bar](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/foo-bar.png)

## 观察模块运行

从日志可以看出,ethereum的p2p模块功能非常完备，在由种子节点接入网络后,可以自动完成节点发现，并且不断刷新自身的连接表，对已经建立的节点链路发送心跳保持连接。协议数据包使用rlp格式打包,不管是消息发送还是分拆都对上层提供了极为简单的接口，所以基于次实现高级协议就非常方便了，比如以太坊whisper协议。这是向上的延展。

如果要向下深入，那么就可以逐个了解，rlp拆包解包，子协议拓展规则,kad网络节点发现机制,内网穿透，等等


#  real ethereum p2p

回到真实以太坊,geth节点启动最终执行启动p2p网络的地方位于`github.com/ethereum/go-ethereum/node/node.go`文件:

```go
// Start create a live P2P node and starts running it.
func (n *Node) Start() error {
	n.lock.Lock()
	defer n.lock.Unlock()

	// Short circuit if the node's already running
	if n.server != nil {
		return ErrNodeRunning
	}
	if err := n.openDataDir(); err != nil {
		return err
	}

	// Initialize the p2p server. This creates the node key and
	// discovery databases.
	n.serverConfig = n.config.P2P
	n.serverConfig.PrivateKey = n.config.NodeKey()
	n.serverConfig.Name = n.config.NodeName()
	n.serverConfig.Logger = n.log
	if n.serverConfig.StaticNodes == nil {
		n.serverConfig.StaticNodes = n.config.StaticNodes()
	}
	if n.serverConfig.TrustedNodes == nil {
		n.serverConfig.TrustedNodes = n.config.TrustedNodes()
	}
	if n.serverConfig.NodeDatabase == "" {
		n.serverConfig.NodeDatabase = n.config.NodeDB()
	}
	running := &p2p.Server{Config: n.serverConfig}
	n.log.Info("Starting peer-to-peer node", "instance", n.serverConfig.Name)

	// Otherwise copy and specialize the P2P configuration
    ........
}
```

是不是和我们的demo基本一模一样.

具体的协议参考源码文件`github.com/ethereum/go-ethereum/eth/handler.go`子协议管理器`ProtocolManager`

# 本文源码

[本文源码](https://github.com/qjpcpu/ethereum-from-scratch/tree/master/p2p-network)
