---
layout: post
title: "基于以太坊的数字资产"
date: 2018-03-06 18:24:35 +0800
comments: true
categories: blockchain 
---

代币(token)是什么?

<!-- more -->

* 目录
{:toc}

# 什么是代币

通常区块链上由矿工挖出的币种,我们把它称之为初代币，初代币是该区块链最底层的货币，链上的转账及各类基础交易都是以初代币作为结算依据。比如比特币对于比特币区块链，以太币之于以太坊等等。

而通常我们说的代币,或者token(令牌),又指的是什么呢？代币是基于区块链的智能合约定义出的二代币,如果把比特币/以太币比作tcp层的数据包，那么代币就可以类比为http层的http包，它是一个更加上层的概念。

目前市场上发行的代币大部分都是基于以太坊，这是因为以太坊本身是一个图灵完备的区块链，即它的智能合约语言是图灵完备语言。对比起来比特币链上的脚本是非图灵完备的。正是因为以太坊的图灵完备性，使得基于以太坊的开发者可以根据自己的业务需求设计出各种特性各异的代币,它们可以代表任何可替代的可交易商品: 虚拟货币，忠诚点，金牌，白条，游戏内物品等。

## 最小可用代币

标准令牌合约可能相当复杂。但实际上，一个非常基本的令牌归结为:

```javascript
contract MyToken {
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(uint256 initialSupply) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
    }
}
```

阅读这段代码时，请不要拘泥于`token`的字面意思。这里的`MyToken`在发行时限定了发行总额(合约构造函数),同时具备了转账功能`transfer`。那么其实他就是一个简易的货币,具备作为物物交易的中间桥梁来转移价值的能力。

# ERC20

以以太坊为例，由于大家均在链上以大致相同的方式发行了各自的代币，逐渐发现其实这里面有共同的模式可以被提炼出来:由于所有代币都以标准方式实施一些基本功能，这也意味着您的代币将立即与以太坊钱包和任何其他使用相同标准的客户或合同兼容.于是就出现了`ERC20`提案。

## 大纲

```
EIP: 20
Title: ERC-20 Token Standard
Author: Fabian Vogelsteller <fabian@ethereum.org>, Vitalik Buterin <vitalik.buterin@ethereum.org>
Type: Standard
Category: ERC
Status: Accepted
Created: 2015-11-19
```

## 摘要

以下标准定义了在智能合约中实施代币的标准API。该标准提供了传送代币的基本功能，并允许代币被批准，以便其他链上第三方可以使用它们。

## 动机

标准接口允许其他应用程序重新使用以太坊上的任何令牌：从钱包到分散式交换。

## 标准内容

### 方法定义

```javascript
// 可选方法,返回代币名称,如MyToken
function name() constant returns (string name)
// 可选方法，返回代币符号，如EOS
function symbol() constant returns (string symbol)
// 可选方法,返回代币小数位数，如8
function decimals() constant returns (uint8 decimals)

// 货币总发行量
function totalSupply() constant returns (uint256 totalSupply)
// 获取某个账户的代币余额
function balanceOf(address _owner) constant returns (uint256 balance)
// (本人)向某人转账
function transfer(address _to, uint256 _value) returns (bool success)
// (本人)批准只能合约可以向某人转账
function approve(address _spender, uint256 _value) returns (bool success)
// 合约代理from向to转账(须先经过from账户approve)
function transferFrom(address _from, address _to, uint256 _value) returns (bool success)
// 查询_owner允许合约代理向_spender转账的金额
function allowance(address _owner, address _spender) constant returns (uint256 remaining)
```

### 事件定义

```javascript
// 转移代币时必须触发该事件
event Transfer(address indexed _from, address indexed _to, uint256 _value)
// 批准代币时必须触发该事件
event Approval(address indexed _owner, address indexed _spender, uint256 _value)
```

### 范例

[https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/StandardToken.sol](https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/StandardToken.sol)
[https://github.com/ConsenSys/Tokens/blob/master/contracts/eip20/EIP20.sol](https://github.com/ConsenSys/Tokens/blob/master/contracts/eip20/EIP20.sol)

# ERC721

至于erc721的产生是为了解决数字资产唯一性问题。本质上说，erc20的两个代币之间是没有任何区别的，所以它适合作为通用的数字货币来流通，单还有一类有区别的场景，比如数字世界里我的一栋房子和你的一栋房子，他们的面积，朝向，颜色等等都会有区别，是无法同质化标识的，所以就有了erc721.

ERC721官方称谓是:Non-fungible Token Standard(NFT),非同质化代币标准。

ERC721的标准内容我这里不再详述，具体标准可以参考github上以太坊提案,实现实例的话，以太猫就是最好的代表。

### 实用性

许多以太坊智能合约的建议用途都依赖于跟踪单个非同质币（NFTs）。现有或计划中的NFTs 有很多，例如 Decentraland 中的 LAND，与CryptoPunks 项目同名的punks（朋克），以及Dmarket 或 EnjinCoin 等系统的游戏内物品。未来的用途包括检测真实世界中的非同质资产，例如房地产（例如 Ubitquity 或 Propy 等公司所设想的）。在这些情况下，项目在账本中不是“集中在一起的”，相反，每单位代币必须有独立的所有权并自动跟踪，这非常重要。无论这些项目的性质如何，如果我们有一个标准化的接口，并且建立跨功能的NFTs管理和销售平台，这将使得生态系统更加强大。

### NFT IDs

该标准的基础是，每一个 NFT 在跟踪它的合约中，用唯一的一个256 位无符号整数进行标识。每个NFT 的 ID 标号在智能合约的生命周期内不允许改变。元组 ( contract address, asset ID ) 是每个特定 NFT 在以太坊生态系统中的全局唯一且完全合格的标识。虽然某些合约可能觉得 ID 从 0 开始编码，并且对于每一个新 NFT 的 ID 简单增 1 进行编码更加简便，但是使用者绝不能假设 ID 编号具有任何特定模式，并且需要将 ID 编码看做 “黑盒”。

### 向后兼容性

本标准尽可能遵循 ERC-20 的语义，但由于同质代币与非同质代币之间的根本差异，并不能完全兼容 ERC-20。


# 其他问题

## 自动装填gas

每次，您在Ethereum上进行交易，您需要向该块矿工支付费用，以计算您的智能合约的结果。虽然这可能会在未来发生变化，但目前费用只能在以太网中支付，因此您的代币的所有用户都需要它。账户余额小于费用的账户被卡住，直到业主可以支付必要的费用。但在某些使用案例中，您可能不希望用户考虑以太坊，区块链或如何获得以太网，因此只要检测到平衡危险性低，您的硬币就会自动重新填充用户余额。

```javascript
uint minBalanceForAccounts;

function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
     minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
}
/* Send coins */
function transfer(address _to, uint256 _value) {
    ...
    if(msg.sender.balance < minBalanceForAccounts)
        sell((minBalanceForAccounts - msg.sender.balance) / sellPrice);
}
```

# 参考文献

* [干货 | ERC721： Non-fungible Token Standard](http://ethfans.org/posts/eip-721-non-fungible-token-standard)
* [Create your own CRYPTO-CURRENCY with Ethereum](https://ethereum.org/token)
