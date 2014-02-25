---
layout: post
title: "使用expect实现自动登录"
date: 2014-02-25 20:13:57 +0800
comments: true
categories: shell
---

网上有很多类似的文章，但很多都是先写expect脚本再从bash里调用expect脚本，
我希望直接在bash脚本里使用expect命令来实现自动登录。

### 利用expect命令实现自动登录并执行命令

```bash
#!/bin/bash
expect -c '
spawn ssh USER@HOST "commands"
expect {
"*(yes/no)?" { send "yes\r";exp_continue }
"*assword:" { send "PASSWORD\r" }
}
expect eof
'
```

关于expect的命令在网上有很多资料，这里不在赘述。下面讲讲怎么在bash和expect传递变量。

<!--more-->

### 获取登录名及登录密码

从bash中获取变量无非就是获取登录主机及密码，提高代码移植性。这里利用bash的Here document实现。

```bash
#!/bin/bash
host="USER@HOST"
password="PASSWORD"
cmd="command_list"

expect <<EOF 
spawn ssh $host "$cmd"
expect {
"*(yes/no)?" { send "yes\r";exp_continue }
"*assword:" { send "$password\r" }
}
expect eof
EOF
```

bash会自动解析here document中的变量，个人认为这种方式比使用expect的set命令更简便。

### 获取登录执行命令结果

如果希望保持登录，去掉上面代码的`ssh`后的命令列表并且将`expect eof`改成`interact`即可。

但通常我们只是登录到某台机器并执行命令后就返回，同时希望获得命令执行的结果。但上面的代码会混合登录时的部分输出，所以这里可以使用管道过滤一下。

下面的代码展示的怎样获取并输出远程主机的真正命令输出，同时也是一个在here document后接管道操作的例子：

```bash
#!/bin/bash
host="USER@HOST"
password="PASSWORD"
cmd="command_list"

(expect <<EOF 
spawn ssh $host "$cmd"
expect {
"*(yes/no)?" { send "yes\r";exp_continue }
"*assword:" { send "$password\r" }
}
expect eof
EOF
) | awk 'BEGIN{find=0}
{
	if(find){print $0;next}
	if($0 ~ /[pP]assword:/){ find=1 }
}' 
```

这就是在bash中调用expect自动登录的完整代码了。

P.S. 在here document后接管道操作的几种方法：

```bash
# 1
cat <<EOF | sh
echo 1
EOF
# 2
(cat <<EOF
echo 1
EOF
) | sh
# 3
{
cat<<EOF
echo 1
EOF
} | sh
```