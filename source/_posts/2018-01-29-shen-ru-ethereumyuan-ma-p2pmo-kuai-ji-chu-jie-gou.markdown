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

# Peer to peer

在深入了解前,最好先看看基于p2p包实现一个自己子协议,建立对其的直观印象

> 下面示例来基于官方[Peer to peer]wiki文档(官方文档有个小bug, ^_^),详细参考文献


# 参考文献

* [go-ethereum github地址](https://github.com/ethereum/go-ethereum)
* [Peer to Peer](https://github.com/ethereum/go-ethereum/wiki/Peer-to-Peer)
* [基于p2p的底层通信](http://blog.csdn.net/teaspring/article/details/78455046)
