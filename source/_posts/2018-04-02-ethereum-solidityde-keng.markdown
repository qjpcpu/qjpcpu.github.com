---
layout: post
title: "ethereum-solidity的坑"
date: 2018-04-02 10:54:43 +0800
comments: true
categories: blockchain 
---

以太坊合约的坑.

<!-- more -->

# 被意外更改的合约变量

```javascript
pragma solidity ^0.4.11;

contract Test{
    address public a;
    address public b;
    function Test() public{
        a=msg.sender;
        b=msg.sender;
        uint256[2] g=[uint256(0),uint256(0)];
        g[0]=uint256(-1);

    }
}
```

如果`msg.sender`是 `0xca35b7d915458ef540ade6068dfe2f44e8fa733c`,那么想象中的合约变量`a,b`都应该是这个值,但是结果却是:

```
// a: address: 0xffffffffffffffffffffffffffffffffffffffff
// b: address: 0xca35b7d915458ef540ade6068dfe2f44e8fa733c
```

可以看出`a`变成了 `g[0]`的值。 这是因为solidity对于这个未初始化的数组时,把它指向了合约变量地址,所以修改 `g[0]`就相当于修改了 `a`,读者可以试试修改 `g[1]`实际是修改了 `b`.

解决办法是将数组改成`memory`,防止他变成`storage`

```javascript
uint256[2] memory g = [uint256(-1),uint256(-1)];
```
