---
layout: post
title: "git常用操作"
date: 2014-02-14 14:26:31 +0800
comments: true
categories: git
---
<!-- more -->
### 创建远程版本库

1. 设置git

		git config --global user.name "MyName"
		git config --global user.email abcde@example.com

2. 创建版本库
  
    a.新建版本库，并推送到远端

		mkdir TestRepo
		cd TestRepo
		git init
		touch README.md
		git add README.md
		git commit -m 'first commit'
		git remote add origin git@gitserver.com:MyAcountName/TestRepo.git
		git push -u origin master

    b.使用已有本地版本库，并推送到远端
			
		cd TestRepo
		git remote add origin git@gitserver.com:MyAcountName/TestRepo.git
		git push -u origin mast

3. 推/拉

		git push origin master
		git pull origin master


### 克隆已有的远程版本库
	
	git clone  git@gitserver.com:MyAcountName/TestRepo.git  usr1/project
	cd usr1/project
	git config user.name usr1
	git config user.email usr1@example.com
	echo Hello > README
	git add README
	git commit –m “initial commit.”
	git push origin master

### 克隆本地版本库

	git clone  file:///path/to/repo/TestRepo.git  usr2/project