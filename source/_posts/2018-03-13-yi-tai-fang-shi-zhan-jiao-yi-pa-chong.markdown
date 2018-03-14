---
layout: post
title: "以太坊实战-交易爬虫"
date: 2018-03-13 19:46:40 +0800
comments: true
categories: blockchain
---

本文从一个区块链跑路项目说起,怎么通过大家可见的区块数据进行自己的业务分析,目的主要是讲述中间涉及到的技术,如果你能从中获益,并因此构建自己更加强大的分析工具,我深感荣幸.

<!-- more -->

* 目录
{:toc}

# 防止区块链项目跑路

首先要说说这个争议颇多的英雄链: 做为首个全球加密数字货币区块链博彩平台的建设者，HeroChain致力打造数字货币一站式博彩娱乐互动平台，是实现在区块链上加密数字货币的娱乐和产品集合服务平台。HeroChain团队目标是落地与合作全球85个博彩合法的国家和地区，或博彩业合法牌照或与当地博彩业紧密合作，未来使得HEC能与线下赌场打通，使得HEC拥有更大的交易场景。团队认为：HEC的应用覆盖和使用领域确实足以支撑这个巨量加密数字货币的流通市值。由于没有税收，使得HeroChain团队每年可以拿出收益的30%，在进行市场回购HEC， 让参与者获利。关键这个博彩业市场不像之前其它项目的预测的预期市场，是庞大而真实的网络娱乐刚需市场。

从这段描述来看，英雄链所针对的应用场景和未来目标都是非常有说服力的。然而目前出现有用户和项目团队因为破发矛盾激化,进而对该项目本身也产生各种质疑。媒体也对其核心人员的资金流向进行了分析:

![balance flow](https://mmbiz.qpic.cn/mmbiz_jpg/JFoxiaVESXq0R8KvzDkcyicO28Yyo94Ngzl8JoqNXcPxFBgibetLQ74ENNDiaFY1S3gQokIAddFrxI9snaPooY4dWA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1)

从结果来看，项目募集的资金都最终流向了某一个地址，确实存在发行者卷款跑路的可能(详细分析可以查阅参考文献两篇文章)。

我这里只是以这件事件做一个引子，由于区块链的数据对大众完全透明公开,所有人的资金流向其实都摆在眼前，只是说现在链上基础工具不完善，普通人很难去分析这庞大而精细的交易记录。如果我们做一个交易爬虫，能够轻松分析任意账户的资金流动，那么不论是对普通小白验证项目的可信度还是金融从业者分析深度数据，都是很有价值的。

下面，我就介绍下，如果要产生ERC20某个代币的资金流向图(类似下图)，要注意哪些技术关键点。

![hec](https://mmbiz.qpic.cn/mmbiz_png/JFoxiaVESXq0R8KvzDkcyicO28Yyo94NgzgqH5wW9TgI5o4zoBZB3owgvXNbykPhEkEep9zHS5rjqm0GD12BfgRg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1)

# 服务端控制智能合约

要和只能合约进行交互,显然需要完成通用编程语言对合约的控制,这里我们以`golang`代码为例,展示怎么从`golang`中调用合约函数。[官方go-ethereum](https://github.com/ethereum/go-ethereum)已经提供了这样的工具`abigen`,直接从合约`sol`代码生成go代码:

| Command    | Description |
|:----------:|-------------|
| `abigen` | Source code generator to convert Ethereum contract definitions into easy to use, compile-time type-safe Go packages. It operates on plain [Ethereum contract ABIs](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI) with expanded functionality if the contract bytecode is also available. However it also accepts Solidity source files, making development much more streamlined. Please see our [Native DApps](https://github.com/ethereum/go-ethereum/wiki/Native-DApps:-Go-bindings-to-Ethereum-contracts) wiki page for details. |

那我们要分析erc20的代币，所以定义好一份接口合约即可:

```javascript
contract Token {
  function name() constant returns (string name);
    // 可选方法，返回代币符号，如EOS
    function symbol() constant returns (string symbol);
    // 可选方法,返回代币小数位数，如8
    function decimals() constant returns (uint8 decimals);

    // 货币总发行量
    function totalSupply() constant returns (uint256 totalSupply);
    // 获取某个账户的代币余额
    function balanceOf(address _owner) constant returns (uint256 balance);
    // (本人)向某人转账
    function transfer(address _to, uint256 _value) returns (bool success);
    // (本人)批准只能合约可以向某人转账
    function approve(address _spender, uint256 _value) returns (bool success);
    // 合约代理from向to转账(须先经过from账户approve)
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    // 查询_owner允许合约代理向_spender转账的金额
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}
```

然后使用`abigen`工具生成go代码

```bash
abigen --sol ./erc20.sol --pkg erc20 --out token.go
```

然后在`golang`中就可以像这样调用合约函数:

```golang
package main

import (
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// Create an IPC based RPC connection to a remote node
	conn, err := ethclient.Dial("/home/karalabe/.ethereum/testnet/geth.ipc")
	if err != nil {
		log.Fatalf("Failed to connect to the Ethereum client: %v", err)
	}
	// Instantiate the contract and display its name
	token, err := NewToken(common.HexToAddress("0x21e6fc92f93c8a1bb41e2be64b4e1f88a54d3576"), conn)
	if err != nil {
		log.Fatalf("Failed to instantiate a Token contract: %v", err)
	}
	name, err := token.Name(nil)
	if err != nil {
		log.Fatalf("Failed to retrieve token name: %v", err)
	}
	fmt.Println("Token name:", name)
}
```

# ERC20关键参数获取

做交易爬虫,现在最关键的是分析交易参数,比如这是`etherscan.io`上一个`MCAP`转账交易:

![tx](https://raw.githubusercontent.com/qjpcpu/qjpcpu.github.com/master/images/eth-tx.png)

## 某个地址是否合约

在交易里，如果是合约的调用那么`To`字段必然是一个合约地址,那么当我们拿到一个交易时，怎么判断这个交易是否一次合约调用呢，或者怎么判断`To`是合约地址而不是用户钱包地址呢？

```
很简单,地址对应存储位置上有代码则是合约地址,反之是用户钱包
```

理解了这个原理,那么在go代码里就很容易判断了:

```golang
// 某个地址是否合约
func IsContract(conn *ethclient.Client, hexAddr string) bool {
	code, err := conn.CodeAt(context.Background(), common.HexToAddress(hexAddr), nil)
	return err == nil && len(code) > 0
}
```

> 这里附上其他环境判断是否合约的方法

在合约solidity代码里判断:

```javascript
function isContract(address addr) returns (bool) {
  uint size;
  assembly { size := extcodesize(addr) }
  return size > 0;
}
```

在`geth`的console:

```bash
eth.getCode("0xbfb2e296d9cf3e593e79981235aed29ab9984c0f")
```

## From

`From`无法直接从交易函数里获取,因为来源地址可以从签名里反解出来,为了拿取到这个字段,用的方法是解析交易的`String()`输出来获取,虽然办法效率不高,但为了不改动源码这是最简单的。

## To

收款地址的获取就比较麻烦一些了，它不像eth的直接转账,交易的`to`字段就是收款地址,合约调用的`To`是合约地址,真正的收款地址存放在`Data`字段里,那么我们来看看`Data`字段怎么编码的。

### 函数签名

`Data`的起始4个字节是函数签名的sha3结果的前缀,举个例子,对于下面的合约

```javascript
contract Foo {
  function bar(fixed[2] xy) {}
  function baz(uint32 x, bool y) returns (bool r) { r = x > 32 || y; }
  function sam(bytes name, bool z, uint[] data) {}
}
````
如果要调用`baz`函数,则结果应该是`keccak256("baz(uint32,bool)")[0:4]`转换为16进制是`0xcdcd77c0`

### 参数编码

参数编码是依次对函数签名每个参数进行32字节左补齐编码,如`baz(69,true)`这次调用,参数`69`和`true`分别编码结果是:

* `69`,编码为`0x0000000000000000000000000000000000000000000000000000000000000045`
* `true`,编码为`0x0000000000000000000000000000000000000000000000000000000000000001`

那么整合起来,`baz(69,true)`调用时交易的`Data`应该为:

```
0xcdcd77c000000000000000000000000000000000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000001
```

### transfer

回到我们的需求,我们要分析的20代币的转账，其实就是分析`transfer(address _to,unit256 _value)`的合约函数调用,该函数签名编码是`0xa9059cbb`,比如我们要对`0x54d28e24df3a2381d4c072118da0ef0a51a4fcd9`转账`493480000`个MCAP,编码过程为:

```
Function: transfer(address _to, uint256 _value)

MethodID: 0xa9059cbb
[0]:  00000000000000000000000054d28e24df3a2381d4c072118da0ef0a51a4fcd9
[1]:  000000000000000000000000000000000000000000000000000000001d69e840
```

最终结果`Data`是`0xa9059cbb00000000000000000000000054d28e24df3a2381d4c072118da0ef0a51a4fcd9000000000000000000000000000000000000000000000000000000001d69e840`

# Put it together

把这上面关键点整合起来,就可以构建一个简单爬虫,这个爬虫执行流程应该是:

* 遍历区块交易,取到我们关注的某个合约的所有转账交易
* 解析交易关键字段,包含交易ID,from,to,金额,时间戳
* 入库,提供webAPI给应用层

目前我的示例代码仅实现了关键字段解析,但已经足够作为基础函数去做上层分析工具了: [代码地址](https://github.com/qjpcpu/ethereum/blob/master/stats/erc20_crawl.go)

# 参考文献

* [英雄链深度调查 永不说谎的地址](https://mp.weixin.qq.com/s/2wG9-NyeHwan8pgmlaLSwQ)
* [谁是英雄链背后的英雄](https://mp.weixin.qq.com/s/KPIDMwujSZI_MhpmMIG5Gg?scene=25#wechat_redirect)
* [Go bindings to Ethereum contracts](https://github.com/ethereum/go-ethereum/wiki/Native-DApps:-Go-bindings-to-Ethereum-contracts)
* [Ethereum Contract ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI#argument-encoding)
