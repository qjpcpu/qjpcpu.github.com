---
layout: post
title: "hyperledger-fabric分布式部署"
date: 2018-07-23 10:48:30 +0800
comments: true
categories: blockchain
---

fabric官方文档给出了怎样搭建第一个联盟网络([Build your first network](https://hyperledger-fabric.readthedocs.io/en/latest/build_network.html)),然而这个文档实际只给出了单机部署多个docker实例的例子,如果要在真实分布式环境部署，还是得费不少力气.

* 目录
{:toc}


# 基本思路

> 题外话:老实说，fabric这个部署文档写得并不漂亮。因为他引入了过多的先决知识，譬如docker,docker-compose等多个docker组件，虽然使用docker大大提高了部署成功率，然而这样做对于fabric入门来说却走偏了，容易让初学者产生一种疑惑: 好似很容易就"得到"了一个完整的fabric网络，然而实际上，好像对于fabric是怎么运行起来的仍然一无所知。如果想要了解怎么样一步步将fabric搭建起来的话，可以仔细看看`fabric-samples/first-network`文件夹的脚本及compose配置文件，或者参考`[区块链原理、设计、与应用] 作者:杨保华,陈昌`这本书第9章,相信这样的搭建教程才能让人有直观的了解。所以，本文也不必一步步拆分搭建步骤，本文的目的是为了想读者展示如果利用现有的BYFN文档及脚本搭建真正分布式网络。

所有的宿主机环境以及fabric二进制程序的安装还是按照Build Your First Network文档所说进行，在完成后，用docker swarm将各个宿主机上的docker实例连接起来。

# 搭建流程

假设我们有5台宿主机

* orderer(cli) 我们将在orderer宿主机上启动客户端cli配置网络，实际上这个cli可以在任意机器上启动
* peer0.org1
* peer1.org1
* peer0.org2
* peer1.org2

在5台宿主机上同构部署fabric环境，具体操作参考[Build your first network](https://hyperledger-fabric.readthedocs.io/en/latest/build_network.html)

## 创建必要配置文件

在任意一台机器上生成配置文件:

```
cd ./fabric-samples/first-network
./byfn.sh generate
```

然后将生成的配置同步到所有其他几台宿主机的相同目录,同步的文件包含

* channel-artifacts
* crypto-config

## 创建swarm集群

假设我们将cli作为集群manager，则在cli上创建swarm集群:

```
docker swarm init
```

查看集群join token:

```
docker swarm join-token manager
```

输出可能类似这样:

```
docker swarm join — token SWMTKN-1–3as8cvf3yxk8e7zj98954jhjza3w75mngmxh543llgpo0c8k7z-61zyibtaqjjimkqj8p6t9lwgu 172.16.0.153:2377
```

在其他所有机器上执行这条输出的命令，完成后说明所以机器处于同一集群.

## 创建集群网络

在cli宿主机执行

```
docker network create --attachable --driver overlay byfn
```

## 创建fabric控制脚本

现在，所有宿主均处于swarm集群，然而docker-compose并不直接使用swarm,所以我这里不再使用docker-compose，原因有两个: 1.docker-compose主要用于多个服务打包部署，然而我们在每个宿主机仅部署单个docker，不必非要使用compose 2.docker-compose还需要单独配置才能运行在swarm模式下。 所以，我将docker启动命令独立出来，写入一个shell脚本，将这个shell脚本放入所有宿主机`./fabric-samples/first-network/`下命令为`control`文件.

```bash
#!/bin/bash
NETWORK=byfn    # 网络名称必须和创建的集群网络名称一致
IMAGETAG=latest

function startOrderer()
{
    docker run --rm -d --network=${NETWORK} --name orderer.example.com -p 7050:7050 \
    -e ORDERER_GENERAL_LOGLEVEL=INFO \
    -e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 \
    -e ORDERER_GENERAL_GENESISMETHOD=file \
    -e ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block \
    -e ORDERER_GENERAL_LOCALMSPID=OrdererMSP \
    -e ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp \
    -e ORDERER_GENERAL_TLS_ENABLED=true \
    -e ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key \
    -e ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt \
    -e ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt] \
    --mount type=bind,source=/root/fabric/fabric-samples/first-network/channel-artifacts/genesis.block,target=/var/hyperledger/orderer/orderer.genesis.block    \
    --mount type=bind,source=/root/fabric/fabric-samples/first-network/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp,target=/var/hyperledger/orderer/msp    \
    --mount type=bind,source=/root/fabric/fabric-samples/first-network/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/,target=/var/hyperledger/orderer/tls    \
    hyperledger/fabric-orderer:${IMAGETAG} orderer
}


# startPeer 0 1 means start peer 0 of org 1
function startPeer()
{
	PEER=$1
	ORG=$2
	PEER2=1
	[ $PEER -eq 1 ] && PEER2=0
	BOOT=peer${PEER2}.org${ORG}.example.com:7051
    docker run --rm -d  --network=${NETWORK} --name peer${PEER}.org${ORG}.example.com -p 7051:7051 -p 7053:7053 \
    -e CORE_PEER_ID=peer${PEER}.org${ORG}.example.com \
    -e CORE_PEER_ADDRESS=peer${PEER}.org${ORG}.example.com:7051 \
    -e CORE_PEER_GOSSIP_BOOTSTRAP=${BOOT} \
    -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer${PEER}.org${ORG}.example.com:7051 \
    -e CORE_PEER_LOCALMSPID=Org${ORG}MSP \
    -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
    -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=${NETWORK} \
    -e CORE_LOGGING_LEVEL=INFO \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_GOSSIP_USELEADERELECTION=true \
    -e CORE_PEER_GOSSIP_ORGLEADER=false \
    -e CORE_PEER_PROFILE_ENABLED=true \
    -e CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt \
    -e CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt \
    --mount type=bind,source=/var/run/,target=/host/var/run/ \
    --mount type=bind,source=/root/fabric/fabric-samples/first-network/crypto-config/peerOrganizations/org${ORG}.example.com/peers/peer${PEER}.org${ORG}.example.com/msp,target=/etc/hyperledger/fabric/msp \
    --mount type=bind,source=/root/fabric/fabric-samples/first-network/crypto-config/peerOrganizations/org${ORG}.example.com/peers/peer${PEER}.org${ORG}.example.com/tls,target=/etc/hyperledger/fabric/tls \
    hyperledger/fabric-peer:${IMAGETAG}  peer node start
}


# scripts/script.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT
function startCli()
{
    docker run --rm -it --network=${NETWORK} --name cli \
    -e  CHANNEL_NAME="mychannel" \
    -e  CLI_DELAY=3 \
    -e  LANGUAGE=golang \
    -e  CLI_TIMEOUT=10 \
    -e  GOPATH=/opt/gopath \
    -e  CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
    -e  CORE_LOGGING_LEVEL=INFO \
    -e  CORE_PEER_ID=cli \
    -e  CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e  CORE_PEER_LOCALMSPID=Org1MSP \
    -e  CORE_PEER_TLS_ENABLED=true \
    -e  CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt \
    -e  CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key \
    -e  CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    -e  CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    --mount type=bind,source=/var/run/,target=/host/var/run/ \
    --mount type=bind,source=/root/fabric/fabric-samples/chaincode/,target=/opt/gopath/src/github.com/chaincode \
    --mount type=bind,source=/root/fabric/fabric-samples/first-network/crypto-config,target=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ \
    --mount type=bind,source=/root/fabric/fabric-samples/first-network/scripts,target=/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/ \
    --mount type=bind,source=/root/fabric/fabric-samples/first-network/channel-artifacts,target=/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts \
    --workdir /opt/gopath/src/github.com/hyperledger/fabric/peer \
    hyperledger/fabric-tools:${IMAGETAG} /bin/bash
}


case X$1 in
    Xorderer)
        startOrderer
        ;;
    Xpeer)
        startPeer $2 $3
        ;;
    Xcli)
        startCli
        ;;        
    X*)
        echo "Usage: $0 orderer|peer|cli"
        exit -1
        ;;
esac
```

## 启动网络

### 启动orderer

在orderer宿主机执行

```
cd ./fabric-samples/first-network
./contrl orderer
```

### 启动peer

在peer0.org1宿主机执行

```
cd ./fabric-samples/first-network
./contrl peer 0 1
```

在peer1.org1宿主机执行

```
cd ./fabric-samples/first-network
./contrl peer 1 1
```

同理启动org2的peer

### 配置fabric网络

在任意宿主机,这里我们就用orderer宿主机:

```
cd ./fabric-samples/first-network
./control cli
```

执行这个命令后进入客户端配置实例,直接运行配置脚本即可:

```
scripts/script.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT
```

出现的配置及测试输出应该和单机部署一样,至此部署完成。

# 后记

按这个步骤，应该是可以将这个分布式fabric搭建起来的，但是其他优化还需要自行完成，比如为了测试方便，我并没有将区块链数据挂载出来，所以docker重启后区块数据就没有了，生产环境得自己将数据卷挂载上去；还有，为了权限隔离，一般也不会将整个crypto-config文件夹分发给各个联盟节点，而是需要什么给什么，保持目录结构一致即可。
