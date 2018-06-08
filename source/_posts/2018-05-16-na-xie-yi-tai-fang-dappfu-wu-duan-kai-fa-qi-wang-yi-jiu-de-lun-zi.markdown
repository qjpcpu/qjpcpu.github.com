---
layout: post
title: "那些以太坊DApp服务端开发期望已久的轮子"
date: 2018-05-16 17:20:33 +0800
comments: true
categories: blockchain 
---

以太坊虽说是一个去中心化的东西,但DApp却并非是完全去中心化的应用,其主要原因不外乎是以太坊的处理能力和资源有限,无法承载一个完整应用全部的逻辑。所以，目前市面上所有的DApp应用都是需要中心化服务解释的。那么，本文就是列举一些可能会用到的轮子,帮助快速构建应用。

<!-- more -->

* 目录
{:toc}

# nonce管理

重要的放在前面,nonce管理应该是所有以太坊开发者遇到的第一个问题。nonce类似于账户的自增主键,必须连续提交,如果每次都使用`pending nonce`自动提交交易,就会造成之前交易被丢弃,除非你想要替换原交易，否则这可能不是我们期望的结果。

`github.com/qjpcpu/ethereum/ethnonce`包将nonce存储在redis中,使用类似事务的方式申请、使用nonce。

```go
func TestWrap(t *testing.T) {
	mgr := _testinit()
	addr := common.HexToAddress(`0xe35f3e2a93322b61e5d8931f806ff38f4a4f4d88`)
    mgr.SyncNonce(addr)  // 注意,该方法仅在程序第一次运行做初始化时需要调用,或者nonce发生不一致时调用
	tx,err:=mgr.GiveNonceForTx(addr, func(nonce uint64) (*types.Transaction, error) {
        // 向以太坊提交交易
        // 使用nonce manager注入的nonce进行交易提交
		return new(types.Transaction), nil
	})
	if err!=nil {
		t.Fatal(err)
	}
    t.Log(tx)
}
```

P.S. 该包基于redis lua脚本,实现nonce的原子读写,可适用于多协程并行操作。

# 交易重发

对于要做以太坊交易的可靠提交,我相信交易重发绝对是DApp后端程序员的痛点需求。通常,在以太坊拥堵的时候,常常提交的交易会发生"丢失",以太坊浏览器上搜索这笔交易会被提示: `Sorry, we are unable to locate this Transaction Hash`。发生这种情况主要有两个可能: 1.用户给的gas太低,导致交易长时间挂在pending队列不能打包进区块 2. 网络环境恶劣,导致投放的节点丢弃交易(网络环境恶劣只是诱因,其真实的丢包原因是及其复杂的)

`github.com/qjpcpu/ethereum/contracts`提交交易重发的函数

```go
func ResendTransaction(conn *ethclient.Client, tx *types.Transaction, signerFunc bind.SignerFn, nonce uint64, gasPrice *big.Int) (*types.Transaction, error)
```

* conn, eth client
* tx, 需要重发的交易
* signerFunc, 交易签名函数
* nonce, 可选参数,为0表示将交易重发为全新的交易,非0表示替换之前未被打包的交易
* gasPrice,可选参数,为nil表示自动选择合适的price

返回值为重发的新交易数据结构。

通常的使用场景是:

1. 发送交易,并将返回的交易tx marshal为json存储到数据库
2. 定时检查交易是否成功打包
3. 超过超时时间后,调用ResendTransaction重发交易，再进入第1步循环

结合第一步`ethnonce`包管理nonce,可以比较完美实现以太坊可靠交易提交。

简单的代码示例:

```go
signerFunc := contracts.SignerFuncOf(keyJson, keyPwd)
var oldTx *types.Transaction = getLastTxFromDB()
contracts.ResendTransaction(conn, oldTx, signerFunc, oldTx.Nonce(), nil)
```

# 交易备注

交易备注其实就是在交易`data`字段附加一些额外的数据,前端时间有人收费在以太坊永久"刻字"其实就是干的这个事情。那么，抛开这个噱头不说,正常开发中怎么会有这个需求呢?

比如,我们要基于以太坊做一个区块链商品抢购,前端在提交了交易后拿到`metafox`回调后,才能通知到后端是抢购的哪个商品,但是很多时候`metafox`的回调并不可靠,那其实就可以使用交易备注,等后端收到这个交易的event log后,再去查询交易的备注信息就知道了是哪个商品。

相关辅助方法还是在`github.com/qjpcpu/ethereum/contracts`包中,目前交易备注有两种场景

## 裸交易(仅发送eth的交易)

有两个生成交易数据的辅助方法:

```go
// 备注字符串
func PackString(str string) []byte
// 备注一个数字
func PackNum(num *big.Int) []byte
```

## 合约调用交易

也有两个辅助方法,他们均是将备注信息放置在合约方法参数最后:

```go
func PackArgumentsWithNumber(_abi abi.ABI, method string, params ...interface{}) ([]byte, error)
func PackArgumentsWithString(_abi abi.ABI, method string, params ...interface{}) ([]byte, error)
```

最后调用发送`raw`交易的方法提交:

```go
func SendRawTransaction(conn *ethclient.Client, from, to common.Address, value *big.Int, data []byte, signerFunc bind.SignerFn, nonce uint64, gasPrice *big.Int, gasLimit uint64) (*types.Transaction, error)
```

简单的代码示例(不可直接运行):


```go
mgr := GetNonceManager()
_abi, _ := contracts.ParseABI(myABI)
signer := contracts.SignerFuncOf(keyjson, keypwd)
tx, err := mgr.GiveNonceForTx(from_addr, func(nonce uint64) (*types.Transaction, error) {
    // 该合约方法function_name只有一个number参数,后面额外的参数2是备注
	data, err := contracts.PackArgumentsWithNumber(_abi, "function_name", big.Int(1), big.Int(2))
	if err != nil {
		return nil, err
	}
	return contracts.SendRawTransaction(conf.EthConn(), from_addr, getContractAddress(), nil, data, signer, nonce, nil, 0)
})
```

# 事件扫描器

扫描某个/某些事件并更改中心化服务器数据状态,这个需求很常见,直接上代码.

举个例子,扫描 `CryptoKitties` 的怀孕事件:

```go
package main

import (
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/qjpcpu/ethereum/events"
	"os"
)

func main() {
	conn, err := ethclient.Dial("https://api.myetherapi.com/eth")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	dataCh, errCh := make(chan events.Event, 1000), make(chan error, 1)
	b := events.NewScanBuilder()
	rep, err := b.SetClient(conn).
		SetContract(common.HexToAddress(`0x06012c8cf97BEaD5deAe237070F9587f8E7A266d`),abi_text,"Pregnant").
		SetFrom(5547829).
		SetGracefullExit(true).
		BuildAndRun(dataCh, errCh)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	go func() {
		done := rep.WaitChan()
		for {
			select {
			case data := <-dataCh:
				fmt.Printf("%s\n", data.String())
			case err1 := <-errCh:
				fmt.Println("error:", err1)
			case <-done:
				fmt.Println("EXIT")
				return
			}
		}
	}()

	rep.Wait()
}
```

# 登录

以太坊登录其实就是签名和验签.

代码位于包`github.com/qjpcpu/ethereum/key`

示例:

```go
package key

import (
    crand "crypto/rand"
    "github.com/ethereum/go-ethereum/common/hexutil"
    "github.com/ethereum/go-ethereum/crypto"
    "testing"
)

func TestSignature(t *testing.T) {
    pk, err := newKey(crand.Reader)
    if err != nil {
        t.Fatal(err)
    }
    msg := "JasonGeek"
    sign, err := Sign(pk, []byte(msg))
    if err != nil {
        t.Fatal(err)
    }
    from := crypto.PubkeyToAddress(pk.PublicKey).Hex()
    signHex := hexutil.Encode(sign)
    if err := VerifySign(from, signHex, []byte(msg)); err != nil {
        t.Fatal(err)
    }
}
```

# 其他

其他辅助小方法,可能痛点不是那么强烈,我简单列举,有需要的自行参看代码 [qjpcpu/ethereum](https://github.com/qjpcpu/ethereum)

* 获取合约From自段 `func (tx *TransactionWithExtra) From() common.Address`
* 合约是否执行成功 `func (tx *TransactionWithExtra) IsSuccess(conn *ethclient.Client) (bool, error)`
* 某个地址是否是个合约 `func IsContract(conn *ethclient.Client, hexAddr string) bool`
* 交易构造builder `func NewTxOptsBuilder(keyJson, keyPwd string) *TxOptsBuilder`
* 等待交易完成 `func WaitTxDone(conn *ethclient.Client, txhash common.Hash, timeout ...time.Duration) error`
* 根据keystore私钥生成签名方法 `func SignerFuncOf(keyJson, keyPasswd string) bind.SignerFn`
* 直接发送ETH `func TransferETH(conn *ethclient.Client, from, to common.Address, amount *big.Int, signerFunc bind.SignerFn, nonce uint64, gasPrice *big.Int, notes ...string) (*types.Transaction, error)`
* 私钥导入导出 `key`包

# [代码地址qjpcpu/ethereum](https://github.com/qjpcpu/ethereum)
