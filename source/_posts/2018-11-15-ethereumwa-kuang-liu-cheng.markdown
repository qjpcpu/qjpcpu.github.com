---
layout: post
title: "ethereum挖矿流程"
date: 2018-11-15 17:50:36 +0800
comments: true
categories: 
---

本文主要梳理eth挖矿的代码流程结构。

<!-- more -->

* 目录
{:toc}

![miners](https://upload-images.jianshu.io/upload_images/14928134-15681166031820cd.gif?imageMogr2/auto-orient/strip)


![global.png](https://upload-images.jianshu.io/upload_images/14928134-43aa117385c9baea.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

geth的挖矿逻辑都由`miner.Miner`结构管理，在程序启动时，miner主要启动了5个核心协程并行处理挖矿逻辑，其中挖矿worker负责维护4个最关键协程。

## 协程1. newWorkLoop

![work ch.png](https://upload-images.jianshu.io/upload_images/14928134-9d834bbc88ede0cf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


该协程负责周期性地提交新的挖矿任务。当程序启动或者区块同步完成，或者新区块挖掘完毕，`miner.start()`方法会被调用，则`startCh`通道激活，此时协程清理过期的挖矿任务，构建新的挖矿任务并投递到新任务通道`newWorkCh`，等待挖矿执行。

## 协程2. mainLoop

挖矿的主要逻辑都位于该协程。

该协程监听`newWorkCh`通道，接收到新挖矿请求后，开始挖矿。挖矿的逻辑位于`commitNewWork`函数内，如下图所示，首先准备区块头，调用共识引擎`engine.Prepare`准备共识信息，目前的共识使用了PoW共识算法，主要是为区块头计算出本次需要满足的区块PoW难度并写入到区块头；然后再讲收集到达叔区块引入，注意，以太坊最多只能引用2个叔区块，此外，优先引用本地叔区块再引入远端叔区块；然后开始执行收集到pending队列里的交易，也是本地优先远端执行；最后，进行交易后处理，这里也是调用共识引擎`engine.Finalize`实现，主要功能是计算矿工奖励；最后把封装好的区块投递到`taskCh`通道等待挖矿计算验证。

![commitNewWork.png](https://upload-images.jianshu.io/upload_images/14928134-a1898acd67116a44.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

同时还监听`chainSideCh`通道，再检测到叔区块后，如果当前正在挖矿就提交新的叔区块并重新挖矿。

在监听`txsCh`通道时，收到新交易后，如果当前正在挖矿，则执行新交易并重新挖矿，否则直接触发一次新挖矿。

该协程主要都是收集不同信息(交易，叔区块)并封装区块，投递到任务通道准备共识计算。

![task ch.png](https://upload-images.jianshu.io/upload_images/14928134-85f3a82dfefc6ffe.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

另外，这里有个问题，如果前面一个共识计算正在进行中，此时收到新交易或新uncle则立刻进行新的区块，而这两次计算都是针对同一区块(高度)，这样岂不是必然有一次计算浪费？

## 协程3. taskLoop

这一步是挖矿的核心，然而从流程上却是最简单的，就是从`taskCh`获取封装好的区块，进行共识计算，并将成功的结果投递到`resultCh`。

![result ch.png](https://upload-images.jianshu.io/upload_images/14928134-0413b576462ff621.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 协程4. resultLoop

![区块挖出来之后.png](https://upload-images.jianshu.io/upload_images/14928134-ec254a1543e30cf9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

该协程将达成共识的区块(即成功挖出的区块)写入DB,并且向周边p2p节点广播`NewMinedBlockEvent`，然后触发链变更事件(`ChainEvent`+`ChainHeadEvent`或`ChainSideEvent`)，最后将区块插入待确认区块集合。


1. 为什么`resultLoop`变更链事件触发有两种情况(`ChainEvent`+`ChainHeadEvent`)或(`ChainSideEvent`) ?

这是因为写入DB时，会进行链分叉判断，如果当前写入的链难度低，说明需要进行链重组，则次数会导致触发`ChainSideEvent`事件。

另外，注意如果发生链重组，则会从删除旧链的交易:

```go
// reorgs takes two blocks, an old chain and a new chain and will reconstruct the blocks and inserts them
// to be part of the new canonical chain and accumulates potential missing transactions and post an
// event about them
func (bc *BlockChain) reorg(oldBlock, newBlock *types.Block) error {
    // .......
	for _, tx := range diff {
		rawdb.DeleteTxLookupEntry(batch, tx.Hash())
	}
    // ......
}
```

那么删除的交易再什么时候被重新打包的呢？答案是，`txpool`监听了`ChainHeadEvent`事件，当接收到新区块时，会进行分叉判断，再此时会将之前`删除的交易`重新放入交易池等待打包

```go

// reset retrieves the current state of the blockchain and ensures the content
// of the transaction pool is valid with regard to the chain state.
func (pool *TxPool) reset(oldHead, newHead *types.Header) {
	// If we're reorging an old state, reinject all dropped transactions
	var reinject types.Transactions
    // ....
	// Inject any transactions discarded due to reorgs
	log.Debug("Reinjecting stale transactions", "count", len(reinject))
	senderCacher.recover(pool.signer, reinject)
	pool.addTxsLocked(reinject, false)
    // ...
}
```

2. 区块什么时候从`unconfirmed`集合移除?

答案是插入即确认，这个队列时环形的，并且矿工在创建`unconfirmed`队列会指定长度，这个长度即确认高度，当超过这个高度的区块被插入，自然就有最早的区块被移除，达到天然确认的目的。

## 协程5. update

该协程主要保证区块同步和挖矿互斥进行，即同步区块时暂停挖矿，同步完毕启动挖矿。
