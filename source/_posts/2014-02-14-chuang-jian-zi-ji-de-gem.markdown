---
layout: post
title: "创建自己的gem"
date: 2014-02-14 09:45:52 +0800
comments: true
categories: ruby
---

如果在开发过程中遇到比较通用化的场景，并且估计这种情况其他开发者也可能遇到，就可以把解决方案做成ruby gem，放到[rubygems.org](https://rubygems.org)上供所有人使用，并且将源码托管到github上使得解决方案逐步成熟。

以创建一个名为jgem的gem为例，下面就是创建gem的具体步骤：

1. 首先要有[rubygems.org](https://rubygems.org)和[github](https://github.com)的帐号。
2. 利用bundler创建新的gem：

		$ bundle gem jgem
		      create  jgem/Gemfile
		      create  jgem/Rakefile
		      create  jgem/LICENSE.txt
		      create  jgem/README.md
		      create  jgem/.gitignore
		      create  jgem/jgem.gemspec
		      create  jgem/lib/jgem.rb
		      create  jgem/lib/jgem/version.rb
		Initializing git repo in /Users/jason/Documents/tmp/jgem
		
3. 修改`.gemspec`文件，主要修改新gem描述：

		spec.summary       = %q{TODO: Write a short summary. Required.}
		spec.description   = %q{TODO: Write a longer description. Optional.}
	
    添加gem的依赖，包括开发时依赖和运行时依赖：

		spec.add_development_dependency "rake"
		spec.add_runtime_dependency "activerecord"

4. 编译gem

		$ gem build jgem.gemspec 
		WARNING:  no homepage specified
		WARNING:  open-ended dependency on rake (>= 0, development) is not recommended
		  if rake is semantically versioned, use:
		    add_development_dependency 'rake', '~> 0'
		WARNING:  See http://guides.rubygems.org/specification-reference/ for help
		  Successfully built RubyGem
		  Name: jgem
		  Version: 0.0.1
		  File: jgem-0.0.1.gem
		  
	编译后生成jgem-0.0.1.gem。
	
	注意：在每次`gem build`编译gem前，必须`git add .`或`git commit`一次，因为由于gem和git的紧密关系，没有`git add`到暂存区的文件变更很可能不会被编译进gem。有的朋友说在bin目录下创建的可执行文件始终无法被编译进gem就是这个原因（他们采取的办法是将`.gemspec`文件的`spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }`改成`spec.executables =['your_executable_file']`，实际这是不必要的）

5. 发布

    发布生成的gem到rubygems.org。
    
    	$ gem push jgem-0.0.1.gem
    
    根据提示输入用户信息就行了。
    
6. 托管代码

   在github上新建一个代码库，名称最好和gem保持一致为jgem。
   
		git remote add origin git@github.com:USERNAME/jgem.git
		git push -u origin master
		
7. 更新gem代码
   
   如果在本地更新代码，需要先`git add .`或`git commit`，然后执行`gem build`才能正确编译。编译好的gem可以先在本地安装试用：
   
       $ gem build jgem.gemspec
       $ gem install --local jgem-0.0.1.gem
       
   如果要上传到rubygems，则必须更新`jgem/lib/jgem/version.rb`里的版本号，相同的版本号是不允许重复上传的。到rubygems上传的只是编译好的gem，不要忘了提交代码变更到github。
   

   PS. 如果gem需要添加可执行文件如`example_cmd`，在jgem目录下创建bin目录来放置这些命令即可(反复提醒，别忘了将新文件添加到git库哦)。
   
       $ mkdir bin
       $ touch bin/example_cmd
       $ chmod a+x bin/example_cmd