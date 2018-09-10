---
layout: post
title: "[Rebuild Ethereum](二)区块基础结构"
date: 2018-09-10 14:24:59 +0800
comments: true
categories: blockchain 
---


区块链是融合了密码学、分布式技术等等多个计算机领域的产物，虽然这些技术听起来都很高大上，并且不同区块链的源码看起来也都是很庞杂，令人望而生畏，但是我们回归到区块链最本身，她的基础数据结构——“链”，却是很简单的，就是一条单向链表。

<!-- more -->

* 目录
{:toc}


# 数据结构

首先，我们来看看以太坊区块的基本结构(省略了部分非核心成员变量)

```go
// Block represents an entire block in the Ethereum blockchain.
type Block struct {
	header       *Header
	transactions Transactions

	// 省略其他辅助成员
}
```

一个区块主要由两部分组成: `Header`和 `Transactions`列表。

`Transactions`列表就是区块的核心业务数据，无论是ETH的转账，还是某个合约调用，他们都是以一笔笔交易的形式打包到区块里,区块链被称之为分布式账本，那么这些交易就是构成账本的一笔笔流水,通过从账本第一页逐笔交易"翻阅"到最后一页,就可以还原成每个人所以的交易及账户余额。

`Header`是区块链的索引结构，也可以看做单向链表的指向"上一个链节点"的指针，我们所谓的"翻阅"这个行为，其实就是根据这个`Header`指针遍历单向链表的过程。

看到这里，有数据结构基础的同学应该已经非常明白区块链的核心结构了。生产环境的区块链结果不外乎就是这条单向链表在易用性、安全性、传输、存储等多方便调和的产物。

下面我们还是看看以太坊的具体实现。

## Header

```go
// Header represents a block header in the Ethereum blockchain.
type Header struct {
	ParentHash  common.Hash    `json:"parentHash"       gencodec:"required"`
	Number      *big.Int       `json:"number"           gencodec:"required"`

	// 省略其他非结构性成员
}
```

`header`的结构成员有大概15个，这里我们省略了其他和链遍历无关的成员(其他成员也很重要，包含挖矿难度、交易、共识相关参数，只是与本文无关,详细介绍可以参考[从区块头看共识挖矿](http://qjpcpu.github.io/blog/2018/02/24/shen-ru-ethereumyuan-ma-cong-qu-kuai-tou-kan-gong-shi-wa-kuang/)).

结构体里面的`ParentHash`就是上一个区块的"地址"，而这里面还有一个参数`Number`就是我们常说的区块高度。单向链表的指针可以从当前最新区块回溯到创世区块，而`Number`就类似于数组序号，可以方便地直接按区块高度直接访问到某个区块。这个两个参数合起来，可以做到随机访问和顺序访问的双重满足。

> P.S.某个区块的"地址"值由block.Hash()方法获得.

![eth-core-struct1](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/eth-core-struct1.jpeg)

## Transactions

区块中的`Transactions`是交易列表,交易结构就是区块链真正的业务数据。

```go
type Transaction struct {
	data txdata
	// 省略cache成员
}
type txdata struct {
	AccountNonce uint64          `json:"nonce"    gencodec:"required"`
	Price        *big.Int        `json:"gasPrice" gencodec:"required"`
	GasLimit     uint64          `json:"gas"      gencodec:"required"`
	Recipient    *common.Address `json:"to"       rlp:"nil"` // nil means contract creation
	Amount       *big.Int        `json:"value"    gencodec:"required"`
	Payload      []byte          `json:"input"    gencodec:"required"`

	// Signature values
	V *big.Int `json:"v" gencodec:"required"`
	R *big.Int `json:"r" gencodec:"required"`
	S *big.Int `json:"s" gencodec:"required"`

	// This is only used when marshaling to JSON.
	Hash *common.Hash `json:"hash" rlp:"-"`
}
```

* `AccountNonce`是每个账户的交易自增序号,以太坊的个人交易其实是串行执行的，比如同一个账户发出`AccountNonce=10`和`AccountNonce=11`的两笔交易，即便是11先到区块链节点，最终还是需要等待10号交易打包入区块才有可能执行11号交易。
* `Price`就是矿工的快乐源泉用户的头痛症,gasPrice。
* `GasLimit`交易指令执行上限，这也是耳熟能详的参数了。
* `Recipient`交易收据
* `Amount`交易包含的eth
* `Payload`交易体数据包
* `V,R,S`签名数据
* `Hash`交易hash

# 存储结构

以太坊底层使用leveldb作为基础存储层，leveldb是一个高性能的k-v本地存储。那么我们主要看看它是怎么把区块数据组织起来便于CRUD的。

## 区块头

首先是区块头,以太坊中很多时候我们只需要获取区块头，比如轻钱包做区块查询时并不需要获取整个区块数据，仅需要header数据就足够了。

以太坊的区块头是这样的k-v结构:

* `key`:固定前缀h+区块高度大端编码+区块hash
* `value`: rlp编码的header头数据

![eth-core-struct](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/eth-core-struct-header.jpeg)

## 区块体

区块体的存储和区块头非常相似:

* `key`:固定前缀b+区块高度大端编码+区块hash
* `value`:rlp编码的交易列表和叔区块header体

![eth-core-struct](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/eth-core-struct-block.jpeg)

注意交易的数据是存在区块体中的,那么我们平时在使用以太坊浏览器的时候，可能大部分时候都是根据交易hash查询交易，如果每次都要读取区块体才知道交易性能就太低了，所以我们再看看交易存储

## 交易索引

为了便于查询，以太坊额外存储了交易的索引信息:

* `key`:固定前缀l+交易hash
* `value`:区块hash,区块高度,交易在区块中的序号

![eth-core-struct](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/eth-core-struct-tx.jpeg)

## 其他

区块其他存储结构(比如收据,难度td)都以类似的k-v结构存储在leveldb中，他们共同构成了以太坊的存储结构。详细代码比较简单,可以参考`github.com/ethereum/go-ethereum/core/rawdb`和`github.com/ethereum/go-ethereum/ethdb`这两个包。

以太坊的基础数据结构非常简单，在看源码之前最好先熟悉一下。我之前就是忽略了这个基础，在阅读区块重组reorg的代码的时候看到`DeleteTxLookupEntry`以为是删除交易数据，导致对叔区块的理解障碍，后来补看了rawdb源码才知道，这只是删除了交易索引。

# 为什么是单向链表呢？

回到开头，那么为什么大多数区块链都选择了单向链表作为基础数据结构呢，我擅自揣摩可能有这样几点原因:

## 简单

简单既是技术抉择的原因，也是技术成型后的结果。毫无疑问，单向链表是简单的,上完第一节数据结构课的同学应该都能轻松实现一条简单链表。它简单才能易于拓展,才能在这上面方便地设计状态机，从而完成滚动记账。

## 世界线

这里借用一个二次元的概念,区块链的数据是有严格上下文关系的，不能摒弃历史凭空捏造数据，它天生就是交易流水串起来的一条连续的线,这和我们现实世界类似，现实世界的当前状态不过是一个一个事件串联起来的，连续演化出的结果,这就是世界线,它具有状态转移的连续性，唯一性。从这个概念的描述也能感受出，这个业务场景和单向链表也是非常匹配的,我们接触区块链很多时候都是从了解"历史不可篡改"开始，然而链表指向父节点的指针，天然承认了数据历史这一需求。

# 关于rebuild

所以呢，最后我还是偷了个懒，这块的基础结构比较简单,我就不手动写Demo了。
