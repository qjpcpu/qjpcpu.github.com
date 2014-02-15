---
layout: post
title: "rake-ruby's make"
date: 2014-02-14 17:49:14 +0800
comments: true
categories: ruby
---

Rake，顾名思义，就是Ruby的Make工具。

##Rake的特性

Rakefile就是rake版本的makefile文件，它使用的就是标准的ruby语法。不需要编辑XML文件，也不需要记忆古怪的makefile语法。

* 可以定义任务（task），并为任务定义依赖。
* rake支持利用规则模式来合成隐式任务。
* 灵活的文件列表，可以像列表一样操作。
* 预置的库使得编写rakefile变得更加简单。
* 支持并行执行多个任务。

所以说，rakefile文件没有特殊的格式，仅仅是一个包含ruby代码的文件，不过，仍然有一些关于rakefile的约定，遵循这些约定，使得rake能够更好地处理任务和行为。

<!-- more -->

##任务(Task)

Task是rakefile的最重要组成部分。task拥有自己的名称（通常使用符号或字符串命名），一个依赖列表，以及一系列动作（在task的块中定义）。

###简单任务

使用task方法定义任务。task方法接受单个参数作为任务名称。

	task :name

###依赖任务

依赖以列表的形式紧跟任务名。

	task :name => [:prereq1, :prereq2]

### 任务动作

在task方法块中定义动作，块中可以使用任意ruby代码。块中的Ruby代码也可以使用块的参数引用任务对象本身。

	task :name => [:prereq1, :prereq2] do |t|
	  # actions (may reference t)
	end

### 任务的多次定义

一个任务可以被多次定义。每次定义都能增加新的规定到已经存在的任务。该特性使得可以在不同的rakefile文件中定义的任务组合成一个完整任务。例如，下面的任务定义和上面的代码定义了完全相同的任务。

	task :name
	task :name => [:prereq1]
	task :name => [:prereq2]
	task :name do |t|
	  # actions
	end

### 文件任务File Task

实际情况中可能遇到在文件中创建其他文件的情况。如果文件已经存在，文件任务就会跳过该文件。使用方法file（而不是task）可以定义文件任务，此外文件任务名通常使用字符串而不是符号来定义。下面的任务会创建一个可执行程序prog，它依赖于另两个文件a.o和b.o（创建a.o和b.o的任务未写出）。

	file "prog" => ["a.o", "b.o"] do |t|
	  sh "cc -o #{t.name} #{t.prerequisites.join(' ')}"
	end

### 目录任务Directory Task

创建目录也是很常见的任务，这是由directory方法来完成的，它是使用文件任务创建目录的一个快捷方式。如：

	directory "testdata/examples/doc"

等价于：

	file "testdata"              do |t| mkdir t.name end
	file "testdata/examples"     do |t| mkdir t.name end
	file "testdata/examples/doc" do |t| mkdir t.name end

目录任务并不接受依赖和动作定义。但是，可以在定义完成后追加依赖或动作。如：

	directory "testdata"
	file "testdata" => ["otherdata"]
	file "testdata" do
	  cp Dir["standard_data/*.data"], "testdata"
	end

### 并行依赖任务Task with Parallel Prerequisites

Rake可以让依赖任务并行执行：

	multitask :copy_files => [:copy_src, :copy_doc, :copy_bin] do
	  puts "All Copies Complete"
	end

copy_files是一个普通任务，它的动作在所有依赖任务完成后才会执行。但copy_src, copy_doc, copy_bin这三个依赖任务会并行执行，它们各自在自己的ruby线程中执行。如果这三个任务还依赖于某个共同任务pre_for_copy，那么只有当pre_for_copy任务完成后这个三个任务才开始并行执行。

另外，Rake内部的数据结构是线程安全的，所以当执行并行任务时不必考虑同步。但如果使用了某些用户自定义的数据，就可能需要考虑线程安全的问题了。

### 带参数的任务

直接传递参数给需要的任务。如，有个release任务需要版本号作为参数：

	rake release[0.8.2]

版本号字符串0.8.2就会传递给release任务。多个参数可以以逗号分隔的列表的形式传递给任务：

	rake name[john,doe]

注意，rake任务名及其参数是以单个命令行参数传递给rake的，即中间不允许有空格。如果任务名和参数包含空格，就必须进行使用引号：

	rake "name[billy bob, smith]"

### 任务参数和环境参数

任务参数也可以从环境参数获得。如：
	
	rake release[0.8.2]

也可以写成：

	RELEASE_VERSION=0.8.2 rake release

或：

	rake release RELEASE_VERSION=0.8.2

注意：

* 环境参数名要么完全匹配任务定义中的参数，要么和参数全部大写匹配；
* rake命令中声明使用的环境参数不影响系统中的环境变量。

### 带参数任务的定义

必须声明接收参数的任务才能接受参数。定义带参数的任务十分简单：

	task :name, [:first_name, :last_name]

name是任务名，后面的列表是name任务需要接收的参数。利用task块的第二个参数可以在动作中访问传递来的参数：

	task :name, [:first_name, :last_name] do |t, args|
	  puts "First name is #{args.first_name}"
	  puts "Last  name is #{args.last_name}"
	end

块中的t总是绑定为当前任务对象，第二个参数args就是传递进来的参数对象。如果传递了额外的参数，则多余的参数会被忽略；如果缺少参数，那么任务首先会从环境变量中获取，如果没有找到则将参数赋值为nil。

也可以为参数指定默认值：

	task :name, [:first_name, :last_name] do |t, args|
	  args.with_defaults(:first_name => "John", :last_name => "Dough")
	  puts "First name is #{args.first_name}"
	  puts "Last  name is #{args.last_name}"
	end

### 任务接受参数并包含依赖任务

如果任务需要接受参数，并且还依赖于其他任务，则可以这样定义：

	task :name, [:first_name, :last_name] => [:pre_name] do |t, args|
	  args.with_defaults(:first_name => "John", :last_name => "Dough")
	  puts "First name is #{args.first_name}"
	  puts "Last  name is #{args.last_name}"
	end

### 接收额外参数的任务

	task :email, [:message] do |t, args|
	  mail = Mail.new(args.message)
	  recipients = args.extras
	  recipients.each do |target|
	    mail.send_to(recipents)
	  end
	end

此外，可以使用to_a方法将所有参数按顺序转换为列表，包括命名参数和额外参数。

### 以编程方式访问任务

有时我们需要在rakefile中操作任务本身，使用Rake::Task的:[ ]操作符查找任务。例如，:doit任务打印“DONE”，而:dont任务会查找doit任务并且清除其所有依赖和动作。

	task :doit do
	  puts "DONE"
	end
	
	task :dont do
	  Rake::Task[:doit].clear
	end

执行任务：

	$ rake doit
	(in /Users/jim/working/git/rake/x)
	DONE
	$ rake dont doit
	(in /Users/jim/working/git/rake/x)
	$

编程方式处理任务再一次使用了元编程的能力，所以，小心使用该魔法。

## 规则

如果一个文件依赖于别的任务，但却没有为它定义文件任务，rake会尝试查找rakefile定义的规则去合成一个任务。

若我们要调用任务"mycode.o"，但却没有为它定义文件任务，但rakefile文件却含有如下的规则：

	rule '.o' => ['.c'] do |t|
	  sh "cc #{t.source} -c -o #{t.name}"
	end

该规则会合成所有以“.o”结尾的方法。它依赖于以“.c”结尾的源文件。如果rake能找到一个名为"mycode.c"的文件，它就会创建一个任务将mycode.c编译为mycode.o。如果mycode.c文件不存在，rake会递归尝试合成其他规则。

如果任务是由规则合成而来的，那么任务的source属性就被设置为匹配的源文件，这样在规则的动作中就可硬
引用该源文件了。

### 高级规则

规则模式支持正则表达式。此外，   proc块可以用来计算源文件的名称。下面的规则定义和上面的规则是等价的：

	rule( /\.o$/ => [
	  proc {|task_name| task_name.sub(/\.[^.]+$/, '.c') }
	]) do |t|
	  sh "cc #{t.source} -c -o #{t.name}"
	end

下面的任务用于java的编译：

	rule '.class' => [
	  proc { |tn| tn.sub(/\.class$/, '.java').sub(/^classes\//, 'src/') }
	] do |t|
	  java_compile(t.source, t.name)
	end

注意：java_compile是一个假想的调用java编译器的方法。

## 注释

在rakefile中同样可以使用ruby的标准注释（以#开头），但如果希望使用rake -T来显示任务描述，就需要
使用desc命令来描述任务。如：

	desc "Create a distribution package"
	task :package => [ ... ] do ... end

rake -T（或者rake -tasks）会列出所有带描述的任务。如果使用desc来描述任务，就能非常方便的看到rakefile的主要任务。注：-T参数只能列出带desc的任务，如果想列出所有任务，需要使用-P或-prereqs。

## 命名空间

命名空间是用来解决大程序rakefile可能发生的命名冲突问题。

	namespace "main" do
	  task :build do
	    # Build the main program
	  end
	end
	
	namespace "samples" do
	  task :build do
	    # Build the sample programs
	  end
	end
	
	task :build => ["main:build", "samples:build"]

使用 命名空间:任务名 来引用任务，如“main:build”。但注意，在task定义内部获取的任务名是不带命名空间的。

### 文件任务

文件任务和目录任务是不使用命名空间的，因为他们代表真实文件系统中的文件，所以是不会冲突的，故而将他们放置在命名空间中是没有意义的。

### 命名空间解析

当查找任务时，首先在当前命名空间寻找，如果失败则到父命名空间寻找。

“rake”是隐式定义的命名空间，它指代顶级命名空间。

如果一个任务名以“^”打头，那么命名解析会从父级命名空间开始解析。允许使用多个“^”符号。

	task :run
	
	namespace "one" do
	  task :run
	
	  namespace "two" do
	    task :run
	
	    # :run            => "one:two:run"
	    # "two:run"       => "one:two:run"
	    # "one:two:run"   => "one:two:run"
	    # "one:run"       => "one:run"
	    # "^run"          => "one:run"
	    # "^^run"         => "rake:run" (the top level task)
	    # "rake:run"      => "rake:run" (the top level task)
	  end
	
	  # :run       => "one:run"
	  # "two:run"  => "one:two:run"
	  # "^run"     => "rake:run"
	end
	
	# :run           => "rake:run"
	# "one:run"      => "one:run"
	# "one:two:run"  => "one:two:run"

### 文件列表FileList

文件列表基本等同于字符串列表，但建议使用文件列表。下面是创建文件列表的示例：

	fl = FileList['file1.rb', file2.rb']

使用通配符：

	fl = FileList['*.rb']

### do/end和{ }

建议在任务定义时使用do/end，不要使用{ }。

### Rakefile路径

当在终端键入rake命令时，rake会在当前目录下查找rakefile，如果没有则在父目录查找直到找到为止。

### 多个rakefile

并不是所有任务都要在一个单独的rakefile文件中定义，额外的任务可以在应用根目录下的rakelib文件夹中定义，额外的rakefile以".rake"结尾。rails应用的额外rakefile就放置在lib/tasks目录中。

附：如果不在rails环境中使用分离的子rake文件，则可以在根目录的rakefile中这样引用子目录tasks中的子rakefile：

	Dir.glob('tasks/*.rake').each { |r| import r }