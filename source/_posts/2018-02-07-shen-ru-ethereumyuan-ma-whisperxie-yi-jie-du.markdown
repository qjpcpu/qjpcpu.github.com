---
layout: post
title: "深入ethereum源码-whisper协议解读"
date: 2018-02-07 16:13:02 +0800
comments: true
categories: blockchain
---

whisper协议是以太坊DApps之间的通信协议。

<!-- more -->

# 概述

whisper是完全基于`ID`的消息系统,它的设计目的是形成一套p2p节点间的异步广播系统。whisper网络上的消息是加密传送的,完全可以暴露在公网进行传输;此外,为了防范`DDos`攻击,whisper使用了`proof-of-work(PoW)`工作量证明提高消息发送门槛。

# whisper基础构件

whisper协议对上层暴露出一套类似于`订阅-发布`的API模型,节点可以申请自己感兴趣的`topic`，那么就只会接收到这些`topic`的消息,无关主题的消息将被丢弃。在这套体系内，有几个基础构件需要说明下:

## Envelope信封

`envelope即信封`是whisper网络节点传输数据的基本形式。信封包含了加密的数据体和明文的元数据,元数据主要用于基本的消息校验和消息体的解密。

信封是以RLP编码的格式传输:

```
[ Version, Expiry, TTL, Topic, AESNonce, Data, EnvNonce ]
```

* `Version`:最多4字节(目前仅使用了1字节)，如果信封的`Version`比本节点当前值高,将无法解密,仅做转发
* `Expiry`:4字节（unix时间戳秒数）,过期时间
* `TTL`:4字节,剩余存活时间秒数
* `Topic`:4字节,信封主题
* `AESNonce`:12字节随机数据,仅在对称加密时有效
* `Data`:消息体
* `EnvNonce`:8字节任意数据(用于PoW计算)

如果节点无法解密信封，那么节点对信封内的消息内容一无所知，单这并不影响节点将消息进行转发扩散。

## Message消息

信封内的消息体解密后即得到消息内容。


## Topic主题

每个信封上都有一个主题,注意主题可以仅使用部分前缀

## Filter过滤器

`filter`即`订阅-发布`模型中的订阅者

## PoW工作量证明

`PoW`的存在是为了反垃圾信息以及降低网络负担。计算PoW所付出的代价可以理解为抵扣节点为传播和存储信息锁花费的资源.

在`whisperv5`中,`PoW`定义为:

```
PoW = (2^BestBit) / (size * TTL)
```

* `BestBit`是hash计算值的前导0个数
* `size`是消息大小
* `TTL`

具有高`PoW`的消息具有优先处理权。


# 通信流程

whisper协议的实现位于包`github.com/ethereum/go-ethereum/whisper`，该包下面有多个版本实现,目前最新协议包是`whisperv6`.

## whisper main loop

![whisper-main-loop](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/whisper-main-loop.png)

whisper节点启动后产生两个分支:

* 一个分支负责清理`shh.envelopes`中的过期消息
* 另一个分支(proccessQueue)从两个队列取出新接收到的消息,根据消息对应topic投放(Trigger)到对应接收者(filter),从而交付给上层应用进行处理

补充说下whisper里两个队列`messageQueue,p2pMsgQueue`的不同作用,`messageQueue`接收普通的广播消息,`p2pMsgQueue`接收点对点的直接消息,可绕过`pow`和`ttl`限制.

## whisper protocol

whisper协议的具体实现里,代码流程也非常清晰:

![whisper-peer-loop](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/whisper-peer-loop.png)

每个peer连接成功后,产生两个goroutine,进行消息接收和广播:

* 接收消息协程不断从连接中读取新消息,并且将消息暂存到`shh.envelopes`中,如果发现是一条未接收过的新消息,则将消息转发到对应的队列`(messageQueue,p2pMsgQueue)`
* 广播协程负责将该peer未接收过的消息(本节点认为该peer未接收过,并非peer一定没接收过,p2p网络其他节点可能已经将消息广播到该节点了)投递到该peer


# 消息收发
