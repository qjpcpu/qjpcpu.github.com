---
layout: post
title: "solidity备忘录"
date: 2018-03-08 09:38:45 +0800
comments: true
categories: blockchain 
---

关于以太坊solidity语言一些有趣或者有意义的tips.

<!-- more -->

* 目录
{:toc}


# basic sytax

## 字符串比较

`solidity`本身无法直接比较字符串,需要转换成整数比较

```javascript
keccak256("aaaab") != keccak256("bbbbbc");
```

## storage vs memory

* `storage`,变量将存储到链上,如合约变量默认即storage
* `memory`, 内存临时变量

# function

## 访问修饰符

* `public`, 任何人可以调用,包括其他合约
* `private`, 仅本合约可调用
* `internal`, 本合约和继承本合约的合约可调用
* `external`, 仅能外部调用

## 函数修饰符

* `view`, 仅查看数据不修改数据,另外注意`view`修饰符不耗费gas,因为它只做本地查询
* `pure`, 根本不访问(区块链)数据,如仅做内存数学计算

函数修饰符还可以带参数:

```javascript
// 存储用户年龄的映射
mapping (uint => uint) public age;

// 限定用户年龄的修饰符
modifier olderThan(uint _age, uint _userId) {
  require(age[_userId] >= _age);
  _;
}

// 必须年满16周岁才允许开车 (至少在美国是这样的).
// 我们可以用如下参数调用`olderThan` 修饰符:
function driveCar(uint _userId) public olderThan(16, _userId) {
  // 其余的程序逻辑
}
```

# msg

msg对象有几个常用属性

* `msg.sender`, 合约调用者
* `msg.value`, 合约调用者发送的ETH金额


# 接口

接口定义及使用非常简单,不需要额外语言描述.

```javascript
// 声明
contract NumberInterface {
  function getNum(address _myAddress) public view returns (uint);
}

contract MyContract {
  address NumberInterfaceAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E....;
  // ^ The address of the FavoriteNumber contract on Ethereum
  NumberInterface numberContract = NumberInterface(NumberInterfaceAddress);
  // Now numberContract is pointing to the other contract
        
  function someFunction() public {
     // Now we can call getNum from that contract:
     uint num = numberContract.getNum(msg.sender);
    // ...and do something with num here
  }
}
```

接口的使用和实现分离的特点,也是实战中重要特性:解决bugfix,调用外部合同等等灵活场景.

# Ownable

`Ownable`是进行合约管理的常用手段

```javascript
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
```

# 性能优化

通常情况下我们不会考虑使用 unit 变种，因为无论如何定义 uint的大小，Solidity 为它保留256位的存储空间。例如，使用 uint8 而不是uint（uint256）不会为你节省任何gas。

除非，把 unit 绑定到 struct 里面。

如果一个 struct 中有多个 uint，则尽可能使用较小的 uint, Solidity 会将这些 uint 打包在一起，从而占用较少的存储空间。例如：

```javascript
struct NormalStruct {
  uint a;
  uint b;
  uint c;
}

struct MiniMe {
  uint32 a;
  uint32 b;
  uint c;
}
```

// 因为使用了结构打包，`mini` 比 `normal` 占用的空间更少

```javascript
NormalStruct normal = NormalStruct(10, 20, 30);
MiniMe mini = MiniMe(10, 20, 30);
```

所以，当 uint 定义在一个 struct 中的时候，尽量使用最小的整数子类型以节约空间。 并且把同样类型的变量放一起（即在struct中将把变量按照类型依次放置），这样 Solidity 可以将存储空间最小化。例如，有两个 struct：

uint c; uint32 a; uint32 b; 和 uint32 a; uint c; uint32 b;

前者比后者需要的gas更少，因为前者把uint32放一起了。

# 间接转账

直接转账用`who.transfer(value)`,这个很常见, 但有时候还是需要间接转账

## 将发到合约的转账再转给另一个地址

```javascript
function delayTransfer(address _to) public payable {
    _to.transfer(msg.value);
}
```

这个示例就是一个间接转账,这笔转账能够完成的原因其实是,调用这个函数时，用户发过来的eth已经加到合约上了，所以可以再转给第三个地址。

## 将发到合约的eth再转发给另一个合约调用

```javascript
contract Sub {
   address realReceiver;
   function recevice() public payable {
       realReceiver.transfer(msg.value);
   }
}
contract Main{
  Sub sub;
  function transferToSub() public payable{
      sub.recevice.value(msg.value)();
  }
}
```

上面示例将用户的eth通过两次转发最终发给了`realReceiver`.
