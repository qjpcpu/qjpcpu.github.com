---
layout: post
title: "rails 创建数据库索引"
date: 2014-02-14 23:01:32 +0800
comments: true
categories: rails
---

以经典的customer-order为例

1. 在创建数据表时直接创建索引

![image](http://c.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=d1364df8a41ea8d38e227401a7314173/838ba61ea8d3fd1fa3f85879324e251f94ca5f84.jpg?referer=3f089ea983cb39db98d75366999a&x=.jpg)

查看order的migration文件，rails自动为我们添加了index：

![image](http://h.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=a6f85879324e251fe6f7e4fd97bdb82a/960a304e251f95ca360468f5cb177f3e66095284.jpg?referer=b5aa1f650b24ab18b901d5079e9a&x=.jpg)

2. 手动附加索引

此时创建数据表是以普通字段创建的外键

![image](http://h.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=84258bc6cbea15ce45eee00c863b4bce/5ab5c9ea15ce36d35227667338f33a87e950b156.jpg?referer=a621687d79ec54e718fb2f2eff4c&x=.jpg)

如果需要创建索引，就需要手动新建一个migration来添加索引：

![image](http://b.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=d982ea6c97cad1c8d4bbfc224f051634/241f95cad1c8a78620dbb04d6509c93d71cf5084.jpg?referer=e0e8646b952bd4071bd0e7cd909a&x=.jpg)

修改migration文件，手动添加index

![image](http://a.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=97c5064e72cf3bc7ec00cde9e13bcb9c/c83d70cf3bc79f3d08101e73b8a1cd11738b2984.jpg?referer=6e9dc0c00d2442a7f719c995979a&x=.jpg)

3. many-to-many关系中添加index

以man-address为例，直接创建中间表并不会自动添加索引，所以需要在中间表内手动添加索引：

![image](http://h.hiphotos.bdimg.com/album/s%3D550%3Bq%3D90%3Bc%3Dxiangce%2C100%2C100/sign=b5993923372ac65c63056676cbc9c32c/e850352ac65c1038dc5d2b81b0119313b07e8956.jpg?referer=c0dc05118735e5ddc93b90eff74c&x=.jpg)

4. 建议

所有的外键最好都添加索引。