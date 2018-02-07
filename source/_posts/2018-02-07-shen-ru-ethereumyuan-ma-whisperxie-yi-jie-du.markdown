---
layout: post
title: "深入ethereum源码-whisper协议解读"
date: 2018-02-07 16:13:02 +0800
comments: true
categories: blockchain
---

whisper协议是以太坊DApps之间的通信协议。

<!-- more -->

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

* 接收消息协程不断从连接中读取新消息,并且将消息暂存到`shh.envelopes`中,如果发现是一条新消息,则将消息转发到对应的队列`(messageQueue,p2pMsgQueue)`
* 广播协程负责将该peer未接收过的(本节点认为该peer未接收过,并非peer一定没接收过,p2p网络其他节点可能已经将消息广播到该节点了)消息投递到该peer
