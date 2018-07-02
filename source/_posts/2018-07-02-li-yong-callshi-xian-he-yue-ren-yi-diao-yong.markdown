---
layout: post
title: "利用call实现合约任意调用"
date: 2018-07-02 13:50:25 +0800
comments: true
categories: blockchain 
---

call()是一个底层的接口，用来向一个合约发送消息，也就是说如果你想实现自己的消息传递，可以使用这个函数。

<!-- more -->

* 目录
{:toc}

# 需求场景

"合约动态调用"的需求场景是什么呢,答案是"热钱包"。为什么是热钱包呢,我们可以从最终需求出发一步步来推导:

## 业务需求

首先,假设一个业务需求，我们现在要做一个ERC721的热钱包，用户可以托管他全部的数字资产给项目方，项目方代表用户对其资产进行任意操作，这样我们可以向用户屏蔽以太坊的细节，大大提升用户体验，只有当用户想要提现资产的时候，才把资产归还到用户的冷钱包地址中去。

## 明确需求

初看这个需求很简单，我们可以为每个用户生成一个私钥从而建立对应地址。每次需要对资产进行操作的时候，读取这个私钥进行链上交互就行了。

好像很完美，但细想下来，在真正生产环境中实践却会有诸多问题: 首先带来的就是管理问题，众多的私钥不容许有一丝数据的丢失损坏，否则就需要承担用户资产的遗失风险; 其次是泄露的风险，私钥的众多更加大了泄露的风险系数，一旦有任何一个私钥泄露，项目方基本上是属于束手无策的，以太坊上可没有账户封禁这一说。

那么，怎么解决这个问题呢？我这里提供的一个解决方案就是利用合约。

我们为每个用户创建的热钱包并不是一个普通钱包地址，而是一个合约。所有的用户的热钱包都统一受控于项目方的管理账户地址,只有管理账户有权操作合约，如果有任何问题，我们只需要更换管理账户就行，不需要更改其他东西。 但利用合约来做热钱包又带来另一个问题，合约能调用的方法在上链之后就无法更改了或新增了，如果我们要对接的某个721藏品后续支持了某个新方法，那么我们的热钱包岂不是不能完成这个调用了？所以，如果使用合约做热钱包，还必须能够实现这个钱包合约能够动态调用其他合约。

归纳一下，这个721热钱包细化下来的技术需求有这样几点需要满足:

1. 管理收敛，所有热钱包管理最好收敛到一个管理账户下
2. 管理账户能更改
3. 如果是合约热钱包,这个钱包必须能适配各类标准非标准藏品合约的调用

这里对第3点补充说明一下，可能有的读者会疑惑，既然erc721都是标准化的协议，为什么还需要适配各种非标接口呢？原因之一是我们业务需求里已经说了，要能对用户资产进行任意操作，不仅仅限制于基本721的几个API。此外，ERC721的藏品通常都不会只包含721协议里几个基础接口，各个项目方会根据自己的业务研发出诸如繁殖、战斗等等资产操作，一个好的721钱包最好是能适配这些功能。还有，即便是ERC721协议本身，也可能出现变动，比如日前刚确认的721协议的最终版和以CryptoKitty所代表的beta版，协议本身就差别不小。

# 实现关键点

## 调用任意合约

这是本文要讲述的关键点。

其实要实现这个功能,使用`call`方法就可以了。call调用失败会返回一个调用成功与否的布尔值，需要检查一下

```javascript
contract DynamicCaller{
    function dyn_call(address _constract, bytes _data) public payable{
        if (!_constract.call.value(msg.value)(_data)){
            revert();
        }
    }
}
```

如果`DynamicCaller`就是我们的热钱包合约，那么这个`dyn_call`方法就可以实现任意调用，注意这个动态方法最终调用的合约和对应方法都是由参数传递进来；

在ropsten部署这个合约,合约地址是`0x5ec567cf2137da526945f4820d0c0621ddcd02ce`。现在我们有一份任意合约`AnyContract`(这里先不以ERC721合约举例，为了阐明任意调用这个点，使用了一个简单合约示例)

```javascript
contract AnyContract{
    mapping(address => uint256) public numbers;
    mapping(address => string) public texts;
    
    function add(uint256 _a,uint256 _b) public{
        numbers[msg.sender] =_a+_b;
    }
    
    function write(string _text) public{
        texts[msg.sender] = _text;
    }
    
    function batchWrite(uint256 _a,uint256 _b,string _text) public payable{
        numbers[msg.sender] =_a+_b;
        texts[msg.sender] = _text;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}
```

现在我们怎么进行调用呢？我们可以使用`github.com/qjpcpu/ethereum/contracts`提供的参数打包方法`PackArguments`生成`dyn_call`要的数据，比如我们要从`DynamicCaller`调用`AnyContract`的add方法:

```go
anyABI, _ = contracts.ParseABI("[{\"constant\":true,\"inputs\":[{\"name\":\"\",\"type\":\"address\"}],\"name\":\"texts\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"getBalance\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_a\",\"type\":\"uint256\"},{\"name\":\"_b\",\"type\":\"uint256\"}],\"name\":\"add\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_a\",\"type\":\"uint256\"},{\"name\":\"_b\",\"type\":\"uint256\"},{\"name\":\"_text\",\"type\":\"string\"}],\"name\":\"batchWrite\",\"outputs\":[],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"\",\"type\":\"address\"}],\"name\":\"numbers\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_text\",\"type\":\"string\"}],\"name\":\"write\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]")
data, err := contracts.PackArguments(anyABI, "add", big.NewInt(1), big.NewInt(2))
if err != nil {
	return err
}
builder := contracts.NewTxOptsBuilderFromPK(pk)
dc, _ := NewDynamicCaller(common.HexToAddress(DynamicCallerAddres), conn)
tx, err := dc.DynCall(builder.Get(), common.HexToAddress("0x2f44fc640F9708FD969620466F9eddD21859e8E9"), data)
```

完整代码示例参考[dynamic-caller](https://github.com/qjpcpu/dynamic-caller)

## 权限控制

对于热钱包创建合约,需要能更改管理账户,并且`dyn_call`这个函数只有管理账户能够调用,这个继承`Ownable`合约就可能办到了。

对于热钱包合约本身,除了提现操作，所有方法调用必须来自管理合约。

# 实现参考

## 热钱包工厂

热钱包工厂唯一作用就是创建热并记录用户的热钱包，唯一需要注意的就是控制权的管理

```javascript
contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function getOwner() public view returns(address) {
        return owner;
    }

}

contract WalletFactory is Ownable {
    // 记录用户热钱包地址
    mapping(address => address) public hotwallets;

    // 仅管理员owner可以创建热钱包
    function createWallet(address _owner) public onlyOwner {
        // 每个用户仅有一个热钱包
        require(hotwallets[_owner] == address(0));
        HotWallet w = new HotWallet(address(this), _owner);
        hotwallets[_owner] = address(w);
    }
    
    function isWalletFactory() external pure returns(bool){
        return true;
    }
}
```


其实，在实际应用中,这里还潜藏了一个问题: 比如通常的产品逻辑会在用户注册完成时就生成热钱包备用,但这个以太坊交易被打包最快可能也要15秒左右，如果我们要在用户注册完成就显示用户热钱包地址好像是不可能的。实际上呢？交易打包确认确实要很长时间,但是我们却可以提前获知热钱包的地址:

以太坊中合约地址的生成规则是这样的:根据`(msg.sender + nonce)`二元组的hash来生成合约地址的,这个生成算法很简单,有兴趣可以查阅源码`crypto`包。

举个例子,加入`WalletFactory`这个合约地址是`0x5ec567cf2137da526945f4820d0c0621ddcd02ce`,那么第一次调用`createWallet`时nonce肯定是1，则对应生成的`HotWallet`地址可以这样算出: `addr := crypto.CreateAddress(common.HexToAddress("0x5ec567cf2137da526945f4820d0c0621ddcd02ce"), 1) // 热钱包地址是:0xE139cd3E5FcC127A54B0fF8687c703265E282842`

## 热钱包合约


```javascript
contract HotWallet {
    address public owner;
    WalletFactory public factory;
    // 这里的owner是热钱包所属用户
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    // 保证动态方法的调用者一定是管理员
    modifier onlyAdmin() {
        require(msg.sender == factory.getOwner());
        _;
    }
    
    constructor(address _admin, address _owner) public {
        require(_admin != address(0) && _owner != address(0));
        factory = WalletFactory(_admin);
        require(factory.isWalletFactory());
        owner = _owner;
    }
    
    function isHotWallet() external pure returns(bool){
        return true;
    }

    // the msg.sender must be factory.owner
    function dyn_call(address _constract, bytes _data) public payable onlyAdmin {
        if (!_constract.call.value(msg.value)(_data)){
            revert();
        }
    }
    
    // 能提现eth
    function withdraw() external onlyOwner{
        require(owner != address(0));
        owner.transfer(address(this).balance);
    }
    
    // 很多场景下都需要能接受eth转账
    function() public payable{}

    // other functions
}
```

[完整合约代码](https://github.com/qjpcpu/dynamic-caller/blob/master/wallets.sol)

# 后记

要完成个业务特定热钱包,可以在这个基础上修改HotWallet代码即可,比如数字资产的提现等等,但要特别注意: `call`方法是一个非常底层方法，为了合约安全，该方法不应该接受直接来自用户的数据。

此外,我观察到一些交易所给用户分配的以太热钱包地址也是一份用户独立的合约而不是普通地址,所以我猜想他们可能也是为了业务灵活性和管理性才这样做的，不过是不是使用call来实现，就不得而知了。
