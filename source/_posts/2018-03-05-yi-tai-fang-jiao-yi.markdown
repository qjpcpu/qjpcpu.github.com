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

流程中涉及到`nonce`的几个地方:

#### TxPool.validateTx()检查当前交易的`nonce`大于最新区块中账户`nonce`值

```go
// Ensure the transaction adheres to nonce ordering
if pool.currentState.GetNonce(from) > tx.Nonce() {
	return ErrNonceTooLow
}
```

#### 检查`pending`队列中是否有旧交易需要更新

```go
if list := pool.pending[from]; list != nil && list.Overlaps(tx) {
   ...
}
```

`Overlaps()`函数即根据`account,nonce`参数对进行重复检测

#### 尝试将交易加入`pending`队列时检查是否需要剔除过期的nonce

```go
// 检查并剔除小于最新区块的交易
for _, tx := range list.Forward(pool.currentState.GetNonce(addr)) {
   ...
}
```

#### 从队列中获取所有`nonce`值小于等于账户`pending`状态的`nonce`值

```go
for _, tx := range list.Ready(pool.pendingState.GetNonce(addr)) {
   ...
}
```



另外,

* 本地节点low gas的交易并不会被丢弃
* 如果nonce出现"空洞",则空洞后的交易将无法打包

# 关于失败的交易

有时候我们在使用以太坊时交易(转账)时,会遇到一些令人迷惑的失败交易,比如在imToken上转账失败,然而在etherscan.io上无法查到该交易;而有时候又发现失败的转账能够在以太坊浏览器里成功查看到,说明交易是被正确打包上链了,只是交易本身是失败的交易而已，如下图所示,这是一笔因gas过低而失败的交易:

![fail-tx](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/fail-tx.png)


那么我们深入源码来看看是怎么回事.这里我们只跟踪挖矿过程中的失败交易处理,因为普通交易在还没进入到pending队列时的失败的话,是根本不会打包到区块里的。

```go 
func (env *Work) commitTransaction(tx *types.Transaction, bc *core.BlockChain, coinbase common.Address, gp *core.GasPool) (error, []*types.Log) {
  ...
  // 如果执行交易报错,则回滚账户状态(即不从用户账户扣钱,完全回滚,交易不会打包)
  receipt, _, err := core.ApplyTransaction(env.config, bc, &coinbase, gp, env.state, env.header, tx, &env.header.GasUsed, vm.Config{})
  if err != nil {
    env.state.RevertToSnapshot(snap)
    return err, nil
  }
  env.txs = append(env.txs, tx)
  env.receipts = append(env.receipts, receipt)

  return nil, receipt.Logs
}
```

`commitTransaction()`就是在"挖矿"中调用的交易执行函数,其实从该函数就可以看出来:如果执行交易报错,则回滚账户状态,那么交易是不会被打包到区块的.

那么我们继续进入`ApplyTransaction()`看看什么情况下交易会报错,

```go
func ApplyTransaction(config *params.ChainConfig, bc *BlockChain, author *common.Address, gp *GasPool, statedb *state.StateDB, header *types.Header, tx *type$
  // 1.参数检查类错误
  msg, err := tx.AsMessage(types.MakeSigner(config, header.Number))
  if err != nil {
    return nil, 0, err
  }
  ...
  // 2.执行类,稍后再看
  _, gas, failed, err := ApplyMessage(vmenv, msg, gp)
  if err != nil {
    return nil, 0, err
  }
  // 3.存储交易收据,注意失败的交易也会创建收据
  receipt := types.NewReceipt(root, failed, *usedGas)
  receipt.TxHash = tx.Hash()
  receipt.GasUsed = gas
  ...
}
```

`ApplyTransaction()`就比较有意思了,由代码可以看出来,如果是参数检查类错误就直接返回错误,到上层后继续返回就相当于回滚了交易。然而该函数的第二步`ApplyMessage()`实际执行交易返回的后两个值`bool,error`就是关键所在了:

如果返回`error`,那么没什么好说的,错误逐层冒泡出去回滚交易;但如果返回`bool==false,error==nil`,则交易就正确打包了(生成了交易收据打包到区块),但是此时其实交易是执行失败了的,具体我们在进入`ApplyMessage()`,这个函数最终调用到`TransitionDb()`:

```go
unc (st *StateTransition) TransitionDb() (ret []byte, usedGas uint64, failed bool, err error) {
  ...
  // 1. 该函数根据交易数据检查是否超出基本gas限制,会抛出我们常见的vm.ErrOutOfGas(out of gas),注意此处抛出的错误会使得交易完全回滚
  gas, err := IntrinsicGas(st.data, contractCreation, homestead)
  if err = st.useGas(gas); err != nil {
    return nil, 0, false, err
  }

  var (
    evm = st.evm
    vmerr error
  )
  // 2.这里如果返回错误(vmerr!=nil)则说明交易执行失败
  if contractCreation {
    ret, _, st.gas, vmerr = evm.Create(sender, st.data, st.gas, st.value)
  } else {
    // Increment the nonce for the next transaction
    st.state.SetNonce(sender.Address(), st.state.GetNonce(sender.Address())+1)
    ret, st.gas, vmerr = evm.Call(sender, st.to().Address(), st.data, st.gas, st.value)
  }
  if vmerr != nil {
    // 余额不足("insufficient balance for transfer")错误也会导致交易完全回滚
    if vmerr == vm.ErrInsufficientBalance {
      return nil, 0, false, vmerr
    }
  }
  // 退回剩余的gas
  st.refundGas()
  st.state.AddBalance(st.evm.Coinbase, new(big.Int).Mul(new(big.Int).SetUint64(st.gasUsed()), st.gasPrice))

  // 3.vmerr不为空将导致交易失败,但仍能正确打包
  return ret, st.gasUsed(), vmerr != nil, err
}
```

在这个函数里可以看出来,如果交易在以太坊交易执行前报错,那么交易可以完全回滚,然而一旦交易在以太坊虚拟机内执行过程中出错,交易终止退出,消耗的gas并不会退还,这个失败的交易也会被打包到区块中.此外,以太坊中多给的gas并不会浪费掉,gas的消耗完全是按需的,多余的gas会正确退还给发起者:`st.refundGas()`.


综上,对于失败的交易我们能总结出以下几点性质:

* 失败的交易一旦被执行,就一定会被打包到区块链中,并且执行过程中消耗的gas也不会退还,交易的成功与失败可以使用交易的收据状态进行判断
* 失败的交易如果没有打包到区块,那么可能的原因就有很多了,根据交易所处的阶段不同大概有这么几种可能: a.交易gas过低或参数错误根本没有进入到pending队列 b.交易进入pending进行处理,然而在检查gas等参数时报错被丢弃
