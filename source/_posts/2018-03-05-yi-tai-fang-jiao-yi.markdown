---
layout: post
title: "以太坊交易"
date: 2018-03-05 14:26:24 +0800
comments: true
categories: blockchain
---

交易是区块链和重中之重,不论是简单的转账还是复杂的智能合约的执行,都是依托于交易来完成。但是我回头仔细研究了一把以太坊的交易,并梳理这篇文章的原因,仅仅是因为在面试的时候没有回答上来,羞愧......


<!-- more -->

* 目录
{:toc}


# 交易的主要结构

废话不多说,先看看交易的基础数据结构。

```go github.com/ethereum/go-ethereum/core/types/transaction.go
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
* `AccountNonce`,交易发起者内部唯一标识交易的字段,避免交易双重支付
* `Price`,此交易的gas price
* `GasLimit`,此交易允许的最大gas量
* `Recipient`,交易接收者,如果为`nil`说明是个合同创建交易
* `Amount`, 交易转移的`ETH`数量,单位是`wei`
* `Payload`, 交易数据
* `V,R,S`, 交易签名,通过交易签名可以计算出交易发送者地址

# 交易打包流程

![pkg](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/transaction-pkg.png)

## 拼装交易参数

拼装交易参数主要在`github.com/ethereum/go-ethereum/internal/ethapi/api.go setDefaults()`实现。

* `Gas`如果未设置,设置未默认值`90000`
* `GasPrice`如果未设置，设置为建议值
* `Nonce`如果未设置,自动生成nonce值,该值等于当前账户nonce偏移量加上账户nonces数组长度,由此可见账户交易的nonce值是连续递增量

## 对交易签名

首先使用账户的私钥对交易hash信息生成签名,注意该hash计算了包含了`nonce`值和`chainId`.

```go
func (s EIP155Signer) Hash(tx *Transaction) common.Hash {
	return rlpHash([]interface{}{
		tx.data.AccountNonce,
		tx.data.Price,
		tx.data.GasLimit,
		tx.data.Recipient,
		tx.data.Amount,
		tx.data.Payload,
		s.chainId, uint(0), uint(0),
	})
}
```

将签名信息的`0-31`字节放入`R`,`32-63`放入`S`,`64`放入`V`(共65字节).

签名完成后,开始向以太坊提交交易.注意,如果交易的`To`字段为空,说明是个合同创建交易,则自动生成合约地址,合约地址生成规则其实是`hash(from_addr,nonce)`函数:

```go
// Creates an ethereum address given the bytes and the nonce
func CreateAddress(b common.Address, nonce uint64) common.Address {
    data, _ := rlp.EncodeToBytes([]interface{}{b, nonce})
    return common.BytesToAddress(Keccak256(data)[12:])
}
```

## 是否重复交易

通过检查交易池里是否存在该交易hash判断是否是重复交易

```go
    hash := tx.Hash()
    if pool.all[hash] != nil {
        log.Trace("Discarding already known transaction", "hash", hash)
        return false, fmt.Errorf("known transaction: %x", 
```

## 验证交易参数

* 检查交易大小是否小于等于`32KB`,防止DOS攻击
* 检查是否正确签名
* 检查gas是否超过区块gas限制
* 抛弃非local的且gas price偏低的交易
* 检查nonce是否过小
* 检查账户余额是否足够,`balance >= gas_price * gas_limit + amount`

## 丢弃低价交易

如果交易池已满，需要将交易池中低于当前交易的踢出一个,注意踢出的交易仅限于远端交易，本地节点的交易不受影响

```go
// Discard finds a number of most underpriced transactions, removes them from the
// priced list and returns them for further removal from the entire pool.
func (l *txPricedList) Discard(count int, local *accountSet) types.Transactions {
    drop := make(types.Transactions, 0, count) // Remote underpriced transactions to drop
    save := make(types.Transactions, 0, 64)    // Local underpriced transactions to keep

    for len(*l.items) > 0 && count > 0 {
        // Discard stale transactions if found during cleanup
        tx := heap.Pop(l.items).(*types.Transaction)
        if _, ok := (*l.all)[tx.Hash()]; !ok {
            l.stales--
            continue
        }
        // Non stale transaction found, discard unless local
        if local.containsTx(tx) {
            save = append(save, tx)
        } else {
            drop = append(drop, tx)
            count--
        }
    }
    for _, tx := range save {
        heap.Push(l.items, tx)
    }
    return drop
}
```

## 替换重复交易(更新旧交易)

因为交易可以使用`account+nonce`唯一标识,所以如果发现同一账户下已存在同nonce的交易,则视为是对旧交易的一次更新,此时会使用当前交易替换掉旧交易。该机制常用于用来提升gas值避免旧交易长时间得不到处理。

## 提交交易进入交易队列

`promoteExecutables()`将交易从待处理队列移入`pending`队列

* 丢弃过旧的交易,过旧的定义是`nonce`小于当前账户`nonce`值的交易
* 丢弃低余额(账户余额不足以支持交易gas燃烧)
* 丢弃超过账户数量限额的交易
* ...

在一系列交易控制之后,将交易写入`pending`队列,此时交易真正可被矿工打包到区块中。

## 关于交易nonce

* 本地节点low gas的交易并不会被丢弃
* 如果nonce出现"空洞",则空洞后的交易将无法打包,最终导致被丢弃
