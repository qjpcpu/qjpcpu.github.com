---
layout: post
title: "深入ethereum源码-p2p模块基础结构"
date: 2018-01-29 11:19:23 +0800
comments: true
categories: blockchain 
---

(go-ethereum/p2p)包允许您快速方便地将对等网络添加到任何类型的应用程序。p2p包采用模块化结构,包含p2p网络节点通信维护及新节点发现,将网络结构的基础细节封装并向上层屏蔽,并且暴露了简单接口让上层实现子协议,上层应用使用自己的附加子协议扩展p2p非常简单直接.

如果将以太坊的p2p类比做tcp协议,那么p2p暴露出来的子协议就类似http,使得以太坊能够在基础p2p基础上构建出whisper网络。

<!-- more -->

* 目录
{:toc}

# Peer to peer

在深入了解前,最好先看看基于p2p包怎么实现一个自己子协议,建立对其的直观印象

> 下面示例来基于官方[Peer to peer]wiki文档(官方文档有个小bug, ^_^),详细参考文献

启动一个p2p节点仅需要对`p2p.Server`做一些简单配置:

```go
nodekey, _ := crypto.GenerateKey()
srv := p2p.Server{
    Config: p2p.Config{
        MaxPeers:   10,
        PrivateKey: nodekey,
        Name:       "my node name",
        ListenAddr: ":30300",
        Protocols:  []p2p.Protocol{},
        NAT:        nat.Any(),   // 支持内网穿透
        Logger:     log.New(),
    },
}
```

这样启动的节点仅包含了以太坊自身的基础协议:

要实现自己的子协议,就需要拓展`Protocols:  []p2p.Protocol{}`,实现自己的`p2p.Protocol`

```go
func MyProtocol() p2p.Protocol {
	return p2p.Protocol{                                                          // 1.
		Name:    "MyProtocol",                                                    // 2.
		Version: 1,                                                               // 3.
		Length:  1,                                                               // 4.
		Run:     func(peer *p2p.Peer, ws p2p.MsgReadWriter) error { return nil }, // 5.
	}
}
```

1. 一个子协议即一个`p2p.Protocol`
2. 子协议名,需要唯一标识该子协议
3. 协议版本号,当一个子协议有多个版本时,采纳最高版本的协议
4. 该协议拥有的消息类型个数,因为p2p网络是可扩展的，因此其需要具有能够发送随意个数的信息的能力（需要携带type，在下文中我们能够看到说明）,p2p的handler需要知道应该预留多少空间以用来服务你的协议。这是也是共识信息能够通过message ID到达各个peer并实现协商的保障。我们的协议仅仅支持一种类型
5. 在你的协议主要的handler中，我们现在故意将其留空。这个peer变量是指代连接到当前节点，其携带了一些peer本身的信息。其ws变量是reader和writer允许你同该peer进行通信，如果信息能够发送到当前节点，则反之也能够从本节点发送到对端peer节点

现在让我们将前面留空的handler代码实现，以让它能够同别的peer通信:

```go
const messageId = 0   // 1.
type Message string   // 2.

func msgHandler(peer *p2p.Peer, ws p2p.MsgReadWriter) error {
    for {
        msg, err := ws.ReadMsg()   // 3.
        if err != nil {            // 4.
            return err // if reading fails return err which will disconnect the peer.
        }

        var myMessage [1]Message
        err = msg.Decode(&myMessage) // 5.
        if err != nil {
            // handle decode error
            continue
        }
        
        switch myMessage[0] {
        case "foo":
            err := p2p.SendItems(ws, messageId, "bar")  // 6.
            if err != nil {
                return err // return (and disconnect) error if writing fails.
            }
         default:
             fmt.Println("recv:", myMessage)
         }
    }

    return nil
}
```

1. 其中有且唯一的已知信息ID；
2. 将Messages alias 为string类型；
3. ReadMsg将一直阻塞等待，直到其收到了一条新的信息，一个错误或者EOF；
4. 如果在读取流信息的过程当中收到了一个错误，最好的解决实践是将其返回给p2p server进行处理。这种错误通常是对端节点已经断开连接；
5. msg包括两个属性和一个decode方法
    1. Code 包括了信息ID，Code == messageId (i.e.0)
    2. Payload 是信息的内容
    3. Decode(<ptr>) 是一个工具方法：取得 msg.Payload并将其解码，并将其内容设置到传入的message指针中，如果失败了则返回一个error
6. 如果解码出来的信息是foo将发回一个NewMessage并用messageId标记信息类型，信息内容是bar；而bar信息在被对端收到之后将被defaultcase捕获。

现在，我们将上述的所有部分整合起来，得到下面的p2p样例代码:

```go
package main

import (
	"fmt"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/log"
	"github.com/ethereum/go-ethereum/p2p"
	"github.com/ethereum/go-ethereum/p2p/discover"
	"github.com/ethereum/go-ethereum/p2p/nat"
	"net"
	"os"
)

const messageId = 0

type Message string

func MyProtocol() p2p.Protocol {
	return p2p.Protocol{
		Name:    "MyProtocol",
		Version: 1,
		Length:  1,
		Run:     msgHandler,
	}
}
func main() {
	nodekey, _ := crypto.GenerateKey()
	logger := log.New()
	logger.SetHandler(log.StderrHandler)
	srv := p2p.Server{
		Config: p2p.Config{
			MaxPeers:   10,
			PrivateKey: nodekey,
			Name:       "my node name",
			ListenAddr: ":30300",
			Protocols:  []p2p.Protocol{MyProtocol()},
			NAT:        nat.Any(),
			Logger:     logger,
		},
	}
	if err := srv.Start(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Println("started..", srv.NodeInfo())
	select {}
}

func msgHandler(peer *p2p.Peer, ws p2p.MsgReadWriter) error {
	for {
		msg, err := ws.ReadMsg()
		if err != nil {
			return err
		}

		var myMessage [1]Message
		err = msg.Decode(&myMessage)
		if err != nil {
			// handle decode error
			continue
		}

		fmt.Println("code:", msg.Code, "receiver at:", msg.ReceivedAt, "msg:", myMessage)
		switch myMessage[0] {
		case "foo":
			err := p2p.SendItems(ws, messageId, "bar")
			if err != nil {
				return err
			}
		default:
			fmt.Println("recv:", myMessage)
		}
	}
}
```

# peer接入

从上面的例子,我们可以看出来实现ethereum是非常便利的,那么下一步,我们可以看看一个节点是怎么处理新peer的接入的?梳理出这个接入过程,也就明白了节点间基本的数据流通方式.

首先,每个节点启动入口都在`func (srv *Server) Start() (err error)`.该函数调用`srv.startListening()`在传入的ip地址监听tcp连接:

```go
func (srv *Server) startListening() error {
    // Launch the TCP listener.
    listener, err := net.Listen("tcp", srv.ListenAddr)
    ...
    go srv.listenLoop()
    ...
    // 主执行逻辑
    go srv.run(dialer)
    return nil
}
```

当接收到一个新的tcp连接,节点开始检查并初始化peer

```go
func (srv *Server) setupConn(c *conn, flags connFlag, dialDest *discover.Node) error {
    ...
    // 从这里开始,其实已经开始了ethereum的自有协议,doEncHandshake是RLPX协议的握手方法
    if c.id, err = c.doEncHandshake(srv.PrivateKey, dialDest); err != nil {
        srv.log.Trace("Failed RLPx handshake", "addr", c.fd.RemoteAddr(), "conn", c.flags, "err", err)
        return err
    }
    ...
    // 两次握手消息代码(handshakeMsg = 0x00)和(discMsg = 0x01)
    phs, err := c.doProtoHandshake(srv.ourHandshake)
    ...
    // 握手完毕,将新连接对象*p2p.conn压入server.addpeer
    err = srv.checkpoint(c, srv.addpeer)
    // If the checks completed successfully, runPeer has now been
    // launched by run.
    return nil
}
```

下面开始看`Start()`函数里的节点主逻辑,主逻辑位于`Start()`末尾的`srv.run()`,该函数逻辑较复杂,我们现在主要看新peer接入的代码:

```go 
func (srv *Server) run(dialstate dialer) {
      ...
      select{
          ...
          case c := <-srv.addpeer:  // 在这里取出之前压入addpeer的连接对象conn
          // 执行到这里表明握手完成,并且通过了节点验证
          err := srv.protoHandshakeChecks(peers, c)
          if err == nil {
              // 创建节点peer对象,传入所有子协议实现,自己实现的子协议就是在这里传入peer的
              p := newPeer(c, srv.Protocols)
              ...
              go srv.runPeer(p)
          }
          ...
      }
      ...

}
```

这里补充说一下`newPeer()`对子协议的一个组织方式:

```go
func matchProtocols(protocols []Protocol, caps []Cap, rw MsgReadWriter) map[string]*protoRW {
    // 按协议(name asc,version asc)排序子协议
    sort.Sort(capsByNameAndVersion(caps))
    // 自定义协议偏移
    offset := baseProtocolLength
    result := make(map[string]*protoRW)

outer:
    for _, cap := range caps {
        for _, proto := range protocols {
            if proto.Name == cap.Name && proto.Version == cap.Version {
                // If an old protocol version matched, revert it
                if old := result[cap.Name]; old != nil {
                    offset -= old.Length
                }
                // Assign the new match
                result[cap.Name] = &protoRW{Protocol: proto, offset: offset, in: make(chan Msg), w: rw}
                offset += proto.Length

                continue outer
            }
        }
    }
    return result
}
```

最终每个子协议以`name=>protocol`的map格式组织起来,然后每个协议根据自身支持消息类型数量`Protocol.Length`在整个以太坊消息类型轴上占据了`[proto.offset,proto.offset+proto.Length)`的左闭右开消息类型段,理解这个结构,才好理解最终根据消息类型`Msg.Code`去找handler的逻辑(`func (p *Peer) getProto(code uint64) (*protoRW, error)`)。

下面继续看最终peer处理逻辑`srv.runPeer`:

```go
func (p *Peer) run() (remoteRequested bool, err error) {
    ...
    // peer逻辑里最重要两个循环逻辑

    // 收取消息循环,核心逻辑是根据消息的代号proto, err := p.getProto(msg.Code),
    // 取得对应的子协议,然后投放到对应协议的读队列proto.in <- msg
    go p.readLoop(readErr)
    // 不停发送ping心跳包到远端peer
    go p.pingLoop()

    // 在startProtocols里最终调用我们自定义子协议的Run方法proto.Run(p, rw)
    p.startProtocols(writeStart, writeErr)
    ...
}
```

# 数据传输格式RLP

以太坊数据传输都是基于RLP编码,下面文字摘自[RLP编码原理](http://ethfans.org/posts/415)

> RLP(Recursive Length Prefix，递归长度前缀)是一种编码算法，用于编码任意的嵌套结构的二进制数据，它是以太坊中数据序列化/反序列化的主要方法，区块、交易等数据结构在持久化时会先经过RLP编码后再存储到数据库中

定义

> RLP编码的定义只处理两类数据：一类是字符串（例如字节数组），一类是列表。字符串指的是一串二进制数据，列表是一个嵌套递归的结构，里面可以包含字符串和列表，例如`["cat",["puppy","cow"],"horse",[[]],"pig",[""],"sheep"]`就是一个复杂的列表。其他类型的数据需要转成以上的两类，转换的规则不是RLP编码定义的，可以根据自己的规则转换，例如struct可以转成列表，int可以转成二进制（属于字符串一类），以太坊中整数都以大端形式存储。

这部分代码均位于`github.com/ethereum/go-ethereum/rlp`包中,代码相对独立,我也没深入研究改算法,就不详细说明了。

# 总述

本文主要梳理了以太坊p2p模块的主流程,描述了核心的peer间数据读写的来龙去脉,从代码里也能够比较容易理解以太坊子协议的概念,理清这个主干流程,以后也就能够从每个细节发散开来,深入细节。

# 参考文献

* [go-ethereum github地址](https://github.com/ethereum/go-ethereum)
* [Peer to Peer](https://github.com/ethereum/go-ethereum/wiki/Peer-to-Peer)
* [基于p2p的底层通信](http://blog.csdn.net/teaspring/article/details/78455046)
* [RLP](https://github.com/ethereum/wiki/wiki/%5B%E4%B8%AD%E6%96%87%5D-RLP)
* [RLP编码原理](http://ethfans.org/posts/415)
