---
layout: post
title: "hyperledger-fabric服务端开发"
date: 2018-07-25 14:23:59 +0800
comments: true
categories: blockchain 
---

这篇文章并不是介绍fabric智能合约怎么编写的,因为这类的文章随便在google上一搜一大把. 但反而是fabric服务端开发应该怎么做需要有人稍稍点拨一下。本文就以golang服务端为例，介绍一下fabric服务端基本做法。

<!-- more -->

* 目录
{:toc}

# fabric-sdk-go

fabric目前主要提供了`node`和`go`的SDK，我们将以`[go](https://github.com/hyperledger/fabric-sdk-go)`为例搭建一个简单服务端程序。

首先安装fabric开发基础库:

```bash
go get -u github.com/hyperledger/fabric/orderer
go get -u github.com/hyperledger/fabric/peer
go get -u github.com/hyperledger/fabric-sdk-go

# Optional - populate vendor directory (if needed by your downstream vendoring solution)
# cd $GOPATH/src/github.com/hyperledger/fabric-sdk-go/
# make populate
```

# 准备基础配置文件

首先准备一份客户端连接的配置文件，配置连接orderer、peer节点，证书路径等信息:

```yaml config_e2e.yaml
#
# Schema version of the content. Used by the SDK to apply the corresponding parsing rules.
#
version: 1.0.0

#
# The client section used by GO SDK.
#
client:

  # Which organization does this application instance belong to? The value must be the name of an org
  # defined under "organizations"
  organization: org1

  logging:
    level: info

  # Root of the MSP directories with keys and certs.
  cryptoconfig:
    path: /home/ubuntu/.local/src/playfabric/first-network/crypto-config

  # Some SDKs support pluggable KV stores, the properties under "credentialStore"
  # are implementation specific
  credentialStore:
    # [Optional]. Used by user store. Not needed if all credentials are embedded in configuration
    # and enrollments are performed elswhere.
    path: "/tmp/state-store"

    # [Optional]. Specific to the CryptoSuite implementation used by GO SDK. Software-based implementations
    # requiring a key store. PKCS#11 based implementations does not.
    cryptoStore:
      # Specific to the underlying KeyValueStore that backs the crypto key store.
      path: /tmp/msp

   # BCCSP config for the client. Used by GO SDK.
  BCCSP:
    security:
     enabled: true
     default:
      provider: "SW"
     hashAlgorithm: "SHA2"
     softVerify: true
     level: 256

  tlsCerts:
    # [Optional]. Use system certificate pool when connecting to peers, orderers (for negotiating TLS) Default: false
    systemCertPool: false

channels:
  # name of the channel
  mychannel:
    # Required. list of peers from participating orgs
    peers:
      peer0.org1.example.com:
        # [Optional]. will this peer be sent transaction proposals for endorsement? The peer must
        # have the chaincode installed. The app can also use this property to decide which peers
        # to send the chaincode install request. Default: true
        endorsingPeer: true

        # [Optional]. will this peer be sent query proposals? The peer must have the chaincode
        # installed. The app can also use this property to decide which peers to send the
        # chaincode install request. Default: true
        chaincodeQuery: true

        # [Optional]. will this peer be sent query proposals that do not require chaincodes, like
        # queryBlock(), queryTransaction(), etc. Default: true
        ledgerQuery: true

        # [Optional]. will this peer be the target of the SDK's listener registration? All peers can
        # produce events but the app typically only needs to connect to one to listen to events.
        # Default: true
        eventSource: true

    # [Optional]. The application can use these options to perform channel operations like retrieving channel
    # config etc.
    policies:
      #[Optional] options for retrieving channel configuration blocks
      queryChannelConfig:
        #[Optional] min number of success responses (from targets/peers)
        minResponses: 1
        #[Optional] channel config will be retrieved for these number of random targets
        maxTargets: 1
        #[Optional] retry options for query config block
        retryOpts:
          #[Optional] number of retry attempts
          attempts: 5
          #[Optional] the back off interval for the first retry attempt
          initialBackoff: 500ms
          #[Optional] the maximum back off interval for any retry attempt
          maxBackoff: 5s
          #[Optional] he factor by which the initial back off period is exponentially incremented
          backoffFactor: 2.0

#
# list of participating organizations in this network
#
organizations:
  org1:
    mspid: Org1MSP

    # This org's MSP store (absolute path or relative to client.cryptoconfig)
    cryptoPath:  peerOrganizations/org1.example.com/users/{username}@org1.example.com/msp

    peers:
      - peer0.org1.example.com
      - peer1.org1.example.com

    # [Optional]. Certificate Authorities issue certificates for identification purposes in a Fabric based
    # network. Typically certificates provisioning is done in a separate process outside of the
    # runtime network. Fabric-CA is a special certificate authority that provides a REST APIs for
    # dynamic certificate management (enroll, revoke, re-enroll). The following section is only for
    # Fabric-CA servers.
    certificateAuthorities:
      - ca.org1.example.com

  # the profile will contain public information about organizations other than the one it belongs to.
  # These are necessary information to make transaction lifecycles work, including MSP IDs and
  # peers with a public URL to send transaction proposals. The file will not contain private
  # information reserved for members of the organization, such as admin key and certificate,
  # fabric-ca registrar enroll ID and secret, etc.
  org2:
    mspid: Org2MSP

    # This org's MSP store (absolute path or relative to client.cryptoconfig)
    cryptoPath:  peerOrganizations/org2.example.com/users/{username}@org2.example.com/msp

    peers:
      - peer0.org2.example.com

    certificateAuthorities:
      - ca.org2.example.com

  # Orderer Org name
  ordererorg:
      # Membership Service Provider ID for this organization
      mspID: OrdererMSP

      # Needed to load users crypto keys and certs for this org (absolute path or relative to global crypto path, DEV mode)
      cryptoPath: ordererOrganizations/example.com/users/{username}@example.com/msp


#
# List of orderers to send transaction and channel create/update requests to. For the time
# being only one orderer is needed. If more than one is defined, which one get used by the
# SDK is implementation specific. Consult each SDK's documentation for its handling of orderers.
#
orderers:
  orderer.example.com:
    url: orderer.example.com:7050

    # these are standard properties defined by the gRPC library
    # they will be passed in as-is to gRPC client constructor
    grpcOptions:
      ssl-target-name-override: orderer.example.com
      # These parameters should be set in coordination with the keepalive policy on the server,
      # as incompatible settings can result in closing of connection.
      # When duration of the 'keep-alive-time' is set to 0 or less the keep alive client parameters are disabled
      keep-alive-time: 0s
      keep-alive-timeout: 20s
      keep-alive-permit: false
      fail-fast: false
      # allow-insecure will be taken into consideration if address has no protocol defined, if true then grpc or else grpcs
      allow-insecure: false

    tlsCACerts:
      # Certificate location absolute path
      path: /home/ubuntu/repository/golang-repos/src/playfabric/first-network/crypto-config/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem

#
# List of peers to send various requests to, including endorsement, query
# and event listener registration.
#
peers:
  peer0.org1.example.com:
    # this URL is used to send endorsement and query requests
    url: peer0.org1.example.com:7051
    # eventUrl is only needed when using eventhub (default is delivery service)
    eventUrl: peer0.org1.example.com:7053

    grpcOptions:
      ssl-target-name-override: peer0.org1.example.com
      # These parameters should be set in coordination with the keepalive policy on the server,
      # as incompatible settings can result in closing of connection.
      # When duration of the 'keep-alive-time' is set to 0 or less the keep alive client parameters are disabled
      keep-alive-time: 0s
      keep-alive-timeout: 20s
      keep-alive-permit: false
      fail-fast: false
      # allow-insecure will be taken into consideration if address has no protocol defined, if true then grpc or else grpcs
      allow-insecure: false

    tlsCACerts:
      # Certificate location absolute path
      path: /home/ubuntu/repository/golang-repos/src/playfabric/first-network/crypto-config/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

  peer1.org1.example.com:
    # this URL is used to send endorsement and query requests
    url: peer1.org1.example.com:7151
    # eventUrl is only needed when using eventhub (default is delivery service)
    eventUrl: peer1.org1.example.com:7153

    grpcOptions:
      ssl-target-name-override: peer1.org1.example.com
      # These parameters should be set in coordination with the keepalive policy on the server,
      # as incompatible settings can result in closing of connection.
      # When duration of the 'keep-alive-time' is set to 0 or less the keep alive client parameters are disabled
      keep-alive-time: 0s
      keep-alive-timeout: 20s
      keep-alive-permit: false
      fail-fast: false
      # allow-insecure will be taken into consideration if address has no protocol defined, if true then grpc or else grpcs
      allow-insecure: false

    tlsCACerts:
      # Certificate location absolute path
      path: /home/ubuntu/repository/golang-repos/src/playfabric/first-network/crypto-config/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

  peer0.org2.example.com:
    url: peer0.org2.example.com:8051
    # eventUrl is only needed when using eventhub (default is delivery service)
    eventUrl: peer0.org2.example.com:8053
    grpcOptions:
      ssl-target-name-override: peer0.org2.example.com
      # These parameters should be set in coordination with the keepalive policy on the server,
      # as incompatible settings can result in closing of connection.
      # When duration of the 'keep-alive-time' is set to 0 or less the keep alive client parameters are disabled
      keep-alive-time: 0s
      keep-alive-timeout: 20s
      keep-alive-permit: false
      fail-fast: false
      # allow-insecure will be taken into consideration if address has no protocol defined, if true then grpc or else grpcs
      allow-insecure: false

    tlsCACerts:
      path: /home/ubuntu/repository/golang-repos/src/playfabric/first-network/crypto-config/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
```

# 初始化sdk

使用`github.com/hyperledger/fabric-sdk-go/pkg/core/config`包读取并解析配置文件,加载完成后即可初始化sdk

```go
configPath := os.Getenv("GOPATH") + "/src/playfabric/config_e2e.yaml"
configOpt := config.FromFile(configPath)
sdk, err := fabsdk.New(configOpt)
if err != nil {
	fmt.Println(err)
	os.Exit(1)
}
defer sdk.Close()
```
# 初始化通道

初始化channelContext及channel,至此初始化工作完成，可以操作chain code或者查询账本。

```go
//prepare channel client context using client context
clientChannelContext := sdk.ChannelContext("mychannel", fabsdk.WithUser("User1"), fabsdk.WithOrg(orgName))
// Channel client is used to query and execute transactions (Org1 is default org)
client, err := channel.New(clientChannelContext)
if err != nil {
	fmt.Printf("Failed to create new channel client: %s", err)
	os.Exit(1)
}
```

# 操作ChainCode

以官方example02的chain code（代币转移合约）为例:

```go
// a => b转账2个代币
func executeCC(client *channel.Client) error {
	res, err := client.Execute(channel.Request{ChaincodeID: ccID, Fcn: "invoke", Args: makeArgs("a", "b", "2")},
		channel.WithRetry(retry.DefaultChannelOpts))
	fmt.Println("exe tx:", res.TransactionID)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	return err
}
// 查询某个账户代币余额
func queryCC(client *channel.Client, who string) []byte {
	response, err := client.Query(channel.Request{ChaincodeID: ccID, Fcn: "query", Args: makeArgs(who)},
		channel.WithRetry(retry.DefaultChannelOpts),
		channel.WithTargetEndpoints(),
	)
	fmt.Println("query tx:", response.TransactionID)
	if err != nil {
		fmt.Printf("Failed to query funds: %s", err)
		os.Exit(1)
	}
	return response.Payload
}
```

# 完整示例

完整示例很简单，包含代币转让及查询、底层账本查询（对应fabric1.1，BYFN示例网络）

```go
package main

import (
	"encoding/hex"
	"fmt"
	"github.com/hyperledger/fabric-sdk-go/pkg/client/ledger"
	"github.com/hyperledger/fabric-sdk-go/third_party/github.com/hyperledger/fabric/protos/common"
	"github.com/hyperledger/fabric/common/util"
	"github.com/hyperledger/fabric-sdk-go/pkg/common/errors/retry"
	"github.com/hyperledger/fabric-sdk-go/pkg/client/channel"
	"github.com/hyperledger/fabric-sdk-go/pkg/core/config"
	"github.com/hyperledger/fabric-sdk-go/pkg/fabsdk"
	"os"
)

const (
	channelID      = "mychannel"
	orgName        = "Org1"
	orgAdmin       = "Admin"
	ordererOrgName = "OrdererOrg"
	ccID           = "mycc"
)

func queryLedgerExample() {
	configPath := os.Getenv("GOPATH") + "/src/playfabric/config_e2e.yaml"
	configOpt := config.FromFile(configPath)
	sdk, err := fabsdk.New(configOpt)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer sdk.Close()
	//prepare channel client context using client context
	clientChannelContext := sdk.ChannelContext(channelID, fabsdk.WithUser("User1"), fabsdk.WithOrg(orgName))
	// Channel client is used to query and execute transactions (Org1 is default org)
	client, err := ledger.New(clientChannelContext)
	if err != nil {
		fmt.Printf("Failed to create new channel client: %s", err)
		os.Exit(1)
	}
	ledgerInfo, err := client.QueryInfo()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	printBCI(ledgerInfo.BCI)
	block, err := client.QueryBlock(ledgerInfo.BCI.GetHeight() - 1)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	printBlock(block)
	// txid := "63abb9a2ae8e7f3f689498f4ccedef6001ab7902ba9dfe69e2c270a4f7ff1d4d"
	// tx, err := client.QueryTransaction(fab.TransactionID(txid))
	// if err != nil {
	// 	fmt.Println(err)
	// 	os.Exit(1)
	// }
	// fmt.Println("Tx:", txid, "payload:", hex.EncodeToString(tx.GetTransactionEnvelope().GetPayload()))
}

func printBCI(blk *common.BlockchainInfo) {
	fmt.Println("block height:", blk.GetHeight())
	fmt.Println("block hash:", hex.EncodeToString(blk.GetCurrentBlockHash()))
	fmt.Println("block prevhash:", hex.EncodeToString(blk.GetPreviousBlockHash()))
	fmt.Println("=====================================================")
}

func printBlock(blk *common.Block) {
	fmt.Printf("BlockNO:%v\n", blk.GetHeader().GetNumber())
	fmt.Println("prevhash:", hex.EncodeToString(blk.GetHeader().GetPreviousHash()))
	fmt.Println("hash:", hex.EncodeToString(util.ComputeSHA256(util.ConcatenateBytes(blk.GetData().GetData()...))))
	fmt.Println("=====================================================")
}

func main() {
	configPath := os.Getenv("GOPATH") + "/src/playfabric/config_e2e.yaml"
	configOpt := config.FromFile(configPath)
	sdk, err := fabsdk.New(configOpt)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer sdk.Close()
	//prepare channel client context using client context
	clientChannelContext := sdk.ChannelContext(channelID, fabsdk.WithUser("User1"), fabsdk.WithOrg(orgName))
	// Channel client is used to query and execute transactions (Org1 is default org)
	client, err := channel.New(clientChannelContext)
	if err != nil {
		fmt.Printf("Failed to create new channel client: %s", err)
		os.Exit(1)
	}
	fmt.Println("a", string(queryCC(client, "a")))
	fmt.Println("b", string(queryCC(client, "b")))

	executeCC(client)

	fmt.Println("a", string(queryCC(client, "a")))
	fmt.Println("b", string(queryCC(client, "b")))
}

func executeCC(client *channel.Client) error {
	res, err := client.Execute(channel.Request{ChaincodeID: ccID, Fcn: "invoke", Args: makeArgs("a", "b", "2")},
		channel.WithRetry(retry.DefaultChannelOpts))
	fmt.Println("exe tx:", res.TransactionID)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	return err
}

func queryCC(client *channel.Client, who string) []byte {
	response, err := client.Query(channel.Request{ChaincodeID: ccID, Fcn: "query", Args: makeArgs(who)},
		channel.WithRetry(retry.DefaultChannelOpts),
		channel.WithTargetEndpoints(),
	)
	fmt.Println("query tx:", response.TransactionID)
	if err != nil {
		fmt.Printf("Failed to query funds: %s", err)
		os.Exit(1)
	}
	return response.Payload
}

func makeArgs(args ...string) [][]byte {
	var ccargs [][]byte
	for _, arg := range args {
		ccargs = append(ccargs, []byte(arg))
	}
	return ccargs
}
```

# 其他官方示例

- [E2E Test](test/integration/e2e/end_to_end.go): Basic example that uses SDK to query and execute transaction
- [Ledger Query Test](test/integration/pkg/client/ledger/ledger_queries_test.go): Basic example that uses SDK to query a channel's underlying ledger
- [Multi Org Test](test/integration/e2e/orgs/multiple_orgs_test.go): An example that has multiple organisations involved in transaction
- [Dynamic Endorser Selection](test/integration/pkg/fabsdk/provider/sdk_provider_test.go): An example that uses dynamic endorser selection (based on chaincode policy)
- [E2E PKCS11 Test](test/integration/e2e/pkcs11/e2e_test.go): E2E Test using a PKCS11 crypto suite and configuration
- [CLI](https://github.com/securekey/fabric-examples/tree/master/fabric-cli/): An example CLI for Fabric built with the Go SDK.
