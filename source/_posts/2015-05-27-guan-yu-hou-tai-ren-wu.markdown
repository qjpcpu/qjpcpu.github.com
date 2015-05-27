---
layout: post
title: "关于后台任务"
date: 2015-05-27 17:16:34 +0800
comments: true
categories: ruby 
---

### 关于sidekiq
在做ruby开发时，通常会遇到耗时操作的处理，sidekiq由于其使用简单，性能强劲，所以常被用来作为Ruby应用的后台任务的执行引擎。不过sidekiq有个令人头疼的问题，就是任务提交到后台异步执行后，对于其状态的监测和管理就成为很大的问题。

<!--more-->

sidekiq的wiki上也贴出了很多相关执行管理工具，sidekiq-promise是个人最喜欢的一个，其异步回调的风格和js的风格非常像，使用起来非常友好。

### sidekiq-promise
这里的例子直接来源于其github的readme:

```ruby demo.rb
class ProcessWorker
  include Sidekiq::Promise

  def perform file_to_process
    UnzipWorker.as_promise(file_to_process).then do |dir|
      MrDarcy.all_promises do
        dir.entries.map do |file|
          ImageThumbnailWorker.as_promise(file)
        end
      end
    end.then do
      UserNotificationMailer.all_images_processed
    end
  end
end
```

简述: UnzipWorker会解压文件，然后将解压得到的每个文件分发给ImageThumbnailWorker去创建压缩图，等待所有压缩完成后再发送通知邮件，非常简洁漂亮。

将worker里的`include Sidekiq::Worker`替换成`include Sidekiq::Promise`即可。

如果要获取worker的输出，则调用`ProcessWorker.as_promise(arguments)`即可，在then block中获取执行结果，这个结果即`perform`方法的返回值。

`sidekiq-promise`使用了`MrDarcy`，所以提供了一个很有意思的方法

```ruby
MrDarcy.all_promises do
  [promise1,promise2]
end
```

`MrDarcy.all_promises`的块会等待其中列表的每一个promise完成。
