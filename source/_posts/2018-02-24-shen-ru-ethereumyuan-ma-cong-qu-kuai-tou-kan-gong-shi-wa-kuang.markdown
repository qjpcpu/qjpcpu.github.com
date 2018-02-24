---
layout: post
title: "深入ethereum源码-从区块头看共识挖矿"
date: 2018-02-24 16:09:11 +0800
comments: true
categories: blockchain
---

区块是区块链的基本组成单位,而区块头又是区块的核心数据,本文希望从区块头延展开来,看看区块链的挖矿机制。

<!-- more -->

* 目录
{:toc}

# 区块头的基本数据结构

废话不多说,直接看代码:

```go github.com/ethereum/go-ethereum/core/types/block.go
// Header represents a block header in the Ethereum blockchain.
type Header struct {
    // 1.结构信息
    ParentHash  common.Hash    `json:"parentHash"       gencodec:"required"`
    UncleHash   common.Hash    `json:"sha3Uncles"       gencodec:"required"`
    Number      *big.Int       `json:"number"           gencodec:"required"`

    // 2.挖矿基础信息
    Coinbase    common.Address `json:"miner"            gencodec:"required"`
    GasLimit    uint64         `json:"gasLimit"         gencodec:"required"`
    GasUsed     uint64         `json:"gasUsed"          gencodec:"required"`
    
    // 3.状态信息
    Time        *big.Int       `json:"timestamp"        gencodec:"required"`
    Root        common.Hash    `json:"stateRoot"        gencodec:"required"`
    TxHash      common.Hash    `json:"transactionsRoot" gencodec:"required"`
    ReceiptHash common.Hash    `json:"receiptsRoot"     gencodec:"required"`
    Bloom       Bloom          `json:"logsBloom"        gencodec:"required"`
    
    // 4.挖矿难度控制
    Difficulty  *big.Int       `json:"difficulty"       gencodec:"required"`
    
    // 5.PoW参数
    MixDigest   common.Hash    `json:"mixHash"          gencodec:"required"`
    Nonce       BlockNonce     `json:"nonce"            gencodec:"required"`

    // 6.其他
    Extra       []byte         `json:"extraData"        gencodec:"required"`
}
```

乍一看区块头的字段非常多,别着急,接下来我们逐个分析。按照字段的作用,我们可以将这些字段分成6大类(如代码注释所示),分别控制结构、状态、挖矿等信息,下面我们依次查看.

> 本文引用源码大部分均位于miner/consensus两个包中,代码引用均会给出文件名

# 结构信息

1.`ParentHash`

简单来说,区块链其实是一个单向链表。那么单向链表中必然存在一个将链表串起来的指针,这个指针在区块链里就是`ParentHash`.每个新挖出来的区块都包含了父区块的hash值,这样我们就可以从当前区块一直溯源到创世区块,创世区块hash值为`0x00`.

2.`UncleHash`

类似ParentHash,指向叔区块hash值。

3.`Number`

用于标记当前区块高度,子区块高度一定是父区块+1.

![blockchain-link](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/blockchain-link.png)


构建区块的代码包含在`commitNewWork`函数中,该函数其实就是挖矿主流程所在位置。

```go github.com/ethereum/go-ethereum/miner/worker.go
func (self *worker) commitNewWork(){
    ...
    num := parent.Number()
    header := &types.Header{
        ParentHash: parent.Hash(),          // 父区块的hash
        Number:     num.Add(num, common.Big1),  // 父区块的number+1
        GasLimit:   core.CalcGasLimit(parent),
        Extra:      self.extra,
        Time:       big.NewInt(tstamp),
    }
    ...
}
```

# 挖矿基础信息

1.`Coinbase`

区块链中矿工没挖出一个新区块,都会得到两部分奖励收益:挖矿奖励+手续费,那么这个奖励是到哪个账户的,就是这个coinbase帐号,默认通常是矿工本地第一个账户。

2.`GasUsed`

实际使用的gas,每执行一笔交易往该字段上累积gas值,具体代码可查看`ethereum/go-ethereum/core/state_processor.go:ApplyTransaction`.

3.`GasLimit`

矿工执行交易的上限gas用量,如果执行某个交易时发现gas使用超过这个值则放弃执行后续交易。其数值是基于父区块gas用量来调整,如果`parentGasUsed > parentGasLimit * (2/3)`,则增大该数值，反之则减小。具体实现可参考下面代码实现。

```go github.com/ethereum/go-ethereum/core/block_validator.go
// CalcGasLimit computes the gas limit of the next block after parent.
// This is miner strategy, not consensus protocol.
func CalcGasLimit(parent *types.Block) uint64 {
    // contrib = (parentGasUsed * 3 / 2) / 1024
    contrib := (parent.GasUsed() + parent.GasUsed()/2) / params.GasLimitBoundDivisor

    // decay = parentGasLimit / 1024 -1
    decay := parent.GasLimit()/params.GasLimitBoundDivisor - 1

    /*
        strategy: gasLimit of block-to-mine is set based on parent's
        gasUsed value.  if parentGasUsed > parentGasLimit * (2/3) then we
        increase it, otherwise lower it (or leave it unchanged if it's right
        at that usage) the amount increased/decreased depends on how far away
        from parentGasLimit * (2/3) parentGasUsed is.
    */
    limit := parent.GasLimit() - decay + contrib
    if limit < params.MinGasLimit {
        limit = params.MinGasLimit
    }
    // however, if we're now below the target (TargetGasLimit) we increase the
    // limit as much as we can (parentGasLimit / 1024 -1)
    if limit < params.TargetGasLimit {
        limit = parent.GasLimit() + decay
        if limit > params.TargetGasLimit {
            limit = params.TargetGasLimit
        }
    }
    return limit
}
```

# 状态信息

1.`Time`

新区块的出块时间(按代码描述,严格来说其实是开始挖矿的时间)。

2.`Root`,`TxHash`,`ReceiptHash`

这三个hash值对验证区块意义重大.

`Root`代表的区块链当前所有账户的状态,`TxHash`是本区块所有交易摘要,`ReceiptHash`是本区块所有收据的摘要。

这几个值都是MPT树的root hash值,只要树中任意节点数据有更改，那么这个root hash必然会跟着更改,这就为轻钱包实现提供了可能：不需要下载整个区块的数据,仅使用区块头就可以验证区块的合法性。

> MPT树可以参考文章[Merkle树](http://ethfans.org/posts/Merkle-Patricia-Tree)

3.`Bloom`

区块头里的布隆过滤器是用于搜索收据而构建的。

> [布隆过滤器](https://github.com/cpselvis/zhihu-crawler/wiki/%E5%B8%83%E9%9A%86%E8%BF%87%E6%BB%A4%E5%99%A8%E7%9A%84%E5%8E%9F%E7%90%86%E5%92%8C%E5%AE%9E%E7%8E%B0)

# 挖矿难度控制

1.`Difficulty`

以太坊的挖矿难度是动态调整的,它的难度调整仅和父区块和本区块挖矿时间有关。 而该函数实现里根据启动参数目前有三种难度调整方案:

```go github.com/ethereum/go-ethereum/consensus/ethash/consensus.go
func CalcDifficulty(config *params.ChainConfig, time uint64, parent *types.Header) *big.Int {
    next := new(big.Int).Add(parent.Number, big1)
    switch {
    case config.IsByzantium(next):
        return calcDifficultyByzantium(time, parent)
    case config.IsHomestead(next):
        return calcDifficultyHomestead(time, parent)
    default:
        return calcDifficultyFrontier(time, parent)
    }
}
```

每种策略代码这里不具体展开,总的来说难度值的计算是这样的:

```
本区块难度 = 父区块难度 + 难度调整值 + 难度炸弹
难度调整值 = f(父区块难度,父区块产生时间,本区块产生时间)
难度炸弹 = 2^(区块号/100000 - 2)
```

以太坊的区块难度以单个区块为单位进行调整，可以非常迅速的适应算力的变化，正是这种机制，使以太坊在硬分叉出以太坊经典(ETC)以后没有出现比特币分叉出比特币现金(BCC)后的算力“暴击”问题。同时，以太坊的新区块难度在老区块的基础上有限调整的机制也使区块难度不会出现非常大的跳变

从这个公式可以看出,区块难度短期内仅和难度调整值有关(因为难度炸弹只有每100000个区块才会产生跳变),但是当挖矿到5400000区块后,难度值跳变到非常大,这个时候就不再适合挖矿。 

![eth-diff](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/eth-diff.jpg)

# PoW参数

接下来的两个参数就和无人不知无人不晓的工作量证明息息相关了,以太坊的工作量证明最终拼的就是谁最先得到这两个参数:`MixDigest`和`Nonce`.

目前以太坊线上使用的共识算法是基于PoW的ethash算法,主要实现位于`github.com/ethereum/go-ethereum/consensus/ethash`包中。

PoW算法的思路都大致是相似的,通过暴力枚举猜测一个nonce值,使得根据这个nonce种子计算出的hash值符合约定的难度,这个难度其实就是要求hash值前缀包含多少个0. 

目前以太坊使用的hash是256位,所以将难度折算成前缀0的位数就是:`bits0 = (2^256)/difficulty`,那么我们的代码不停枚举nonce然后将计算得到的hash值前缀0位数和这个做比较就行了,主逻辑代码如下:

```go 
func (ethash *Ethash) mine(block *types.Block, id int, seed uint64, abort chan struct{}, found chan *types.Block) {
    // Extract some data from the header
    var (
        header  = block.Header()
        hash    = header.HashNoNonce().Bytes()
        // 将难度转换得出前缀0的位数
        target  = new(big.Int).Div(maxUint256, header.Difficulty)
        number  = header.Number.Uint64()
        dataset = ethash.dataset(number)
    )
    ...
search:
    for {
        ...
            // Compute the PoW value of this nonce
            digest, result := hashimotoFull(dataset.dataset, hash, nonce)
            if new(big.Int).SetBytes(result).Cmp(target) <= 0 {
                // Correct nonce found, create a new header with it
                header = types.CopyHeader(header)
                header.Nonce = types.EncodeNonce(nonce)
                header.MixDigest = common.BytesToHash(digest)
                ...
            }
            nonce++
         ...
    }
}
```

该函数首先计算出区块难度对应的前缀0位数`target`,然后生成PoW依赖的计算数据集`dataset = ethash.dataset(number)`,最终开始死循环尝试计算`digest, result := hashimotoFull(dataset.dataset, hash, nonce)`,得到结果后将这两个随机数据赋值到区块头对应字段去。

当这个区块成功挖出后，别的区块很容易验证这个区块的PoW是否有效,就使用同样方法产生计算数据集`dataset`,然后调用`hashimotoLight(和hashimotoFull基本一致)`计算出`digest`和区块头的`MixDigest`做比较就可以了。

这里我们跳过了两个重要的步骤:

a.依赖数据集`dataset`的生成实现
b.`hashimotoFull/hashimotoLight`的具体实现

依赖数据集的生成就要说到以太坊的DAG

## DAG

ethash将DAG（有向非循环图）用于工作量证明算法，这是为每个epoch(`epoch := block / epochLength`)生成，例如，每3000个区块（125个小时，大约5.2天）。DAG要花很长时间生成。如果客户端只是按需要生成它，那么在找到新epoch第一个区块之前，每个epoch过渡都要等待很长时间。然而，DAG只取决于区块数量，所以可以预先计算来避免在每个epoch过渡过长的等待时间。Geth和ethminer执行自动的DAG生成，每次维持2个DAG以便epoch过渡流畅。挖矿从控制台操控的时候，自动DAG生成会被打开和关闭。


## hashimoto

> 下面的描述摘自[挖矿和共识算法的奥秘](http://blog.csdn.net/teaspring/article/details/78050274)

hashimoto()的逻辑比较复杂，包含了多次、多种哈希运算。下面尝试从其中数据结构变化的角度来简单描述之：

![hashimoto](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/consensus.png)

简单介绍一下上图所代表的代码流程：

* 首先，hashimoto()函数将入参@hash和@nonce合并成一个40 bytes长的数组，取它的SHA-512哈希值取名seed，长度为64 bytes。
* 然后，将seed[]转化成以uint32为元素的数组mix[]，注意一个uint32数等于4 bytes，故而seed[]只能转化成16个uint32数，而mix[]数组长度32，所以此时mix[]数组前后各半是等值的。
* 接着，lookup()函数登场。用一个循环，不断调用lookup()从外部数据集中取出uint32元素类型数组，向mix[]数组中混入未知的数据。循环的次数可用参数调节，目前设为64次。每次循环中，变化生成参数index，从而使得每次调用lookup()函数取出的数组都各不相同。这里混入数据的方式是一种类似向量“异或”的操作，来自于FNV算法。
* 待混淆数据完成后，得到一个基本上面目全非的mix[]，长度为32的uint32数组。这时，将其折叠(压缩)成一个长度缩小成原长1/4的uint32数组，折叠的操作方法还是来自FNV算法。
* 最后，将折叠后的mix[]由长度为8的uint32型数组直接转化成一个长度32的byte数组，这就是返回值@digest；同时将之前的seed[]数组与digest合并再取一次SHA-256哈希值，得到的长度32的byte数组，即返回值@result。

最终经过一系列多次、多种的哈希运算，hashimoto()返回两个长度均为32的byte数组 - digest[]和result[]。回忆一下ethash.mine()函数中，对于hashimotoFull()的两个返回值，会直接以big.int整型数形式比较result和target；如果符合要求，则将digest取SHA3-256的哈希值(256 bits)，并存于Header.MixDigest中，待以后Ethash.VerifySeal()可以加以验证。


# 其他

1.`Extra`

# 参考文献

* [挖矿和共识算法的奥秘](http://blog.csdn.net/teaspring/article/details/78050274) 
