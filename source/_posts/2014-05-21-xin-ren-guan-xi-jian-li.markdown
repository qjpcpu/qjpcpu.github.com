---
layout: post
title: "信任关系建立"
date: 2014-05-21 14:58:28 +0800
comments: true
categories: shell
---

### 建立host1到host2的信任关系

#### 如果A的rsa文件不存在可以这样建立

首先在`host1`上：

```bash create_rsa.sh   
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
```

#### 添加信任关系

在`host2`上，将`host1`的`~/.ssh/id_rsa.pub`文件内容`追加`到`host2`的`authorized_keys`文件中

#### 避免第一次连接出现添加fingerprint的询问

在`host1`上执行：

```bash
ssh-keyscan host2 >> ~/.ssh/known_hosts
```

<!--more-->

下面是一个示例脚本，在一个中控机上（能同时访问a和b）建立a到b的信任关系：

```bash relation_a2b
#!/bin/bash
if [ "$#" -lt 2 ];then
        echo "Usage: relation_a2b host1 host2"
        exit 1
fi
from=$1
to=$2
key=`ssh $from "ssh-keyscan -t rsa $to >> ~/.ssh/known_hosts && cat ~/.ssh/id_rsa.pub"`
ssh $to "echo $key >> ~/.ssh/authorized_keys"
echo "DONE!"
```

使用方法

```bash
relation_a2b host1 host2
```

