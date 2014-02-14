---
layout: post
title: "rails 创建数据库索引"
date: 2014-02-14 23:01:32 +0800
comments: true
categories: rails
---

以经典的customer-order为例

1. 在创建数据表时直接创建索引

![image](../images/20130622094250171.jpeg)

查看order的migration文件，rails自动为我们添加了index：

![image](../images/20130622094517109.jpeg)

2. 手动附加索引

此时创建数据表是以普通字段创建的外键

![image](../images/20130622094719421.jpeg)

如果需要创建索引，就需要手动新建一个migration来添加索引：

![image](../images/20130622095445515.png)

修改migration文件，手动添加index

![image](../images/20130622095549781.jpeg)

3. many-to-many关系中添加index

以man-address为例，直接创建中间表并不会自动添加索引，所以需要在中间表内手动添加索引：

![image](../images/20130622101142750.jpeg)

4. 建议

所有的外键最好都添加索引。