---
title: Lecture 02 RPC and Threads
author: "Soul Mate"
categories: ["MIT-6.824"]
date: 2019-04-15
url: "/distributed-systems/mit-6.824/lec02-rpc-and-threads-translate.html"
---


# 最多的问题: 为什么使用Go?
**6.824 使用C++许多年**

C++ 工作的很好

但是学生要花时间追踪指针和内存分配的bug, 并且C++没有一个让人满意的RPC包.

**对我们来说, Go相比C++好一点**

- 很好的支持并发 (goroutines, channels, &c)
- 很好的支持RPC
- GC (no use after freeing problems)
- 类型安全
- 线程 + GC 非常有吸引力threads + GC is particularly attractive!
  
**我们喜欢Go语言**

相对简单和保守

在本教程之后, Russ Cox 3月8号将使用 https://golang.org/doc/effective_go.html 进行客座讲座.

# 线程
线程是一种有用的构建工具

Go语言中称之为 goroutines;

其它语言称为线程

线程它们非常棘手

## 为什么使用线程

它们专用于并发, 分布式系统自然存在并发I/O: 

在等待另一个服务器响应时, 多核处理下一个请求: 线程并行运行在多核服务器上

## 线程 = "执行的线程"
线程允许一个程序(逻辑上的) 同时做多件事情

线程共享内存

每个线程包含一些线程状态: 程序计数器, 寄存器, 栈

## 程序中有多少线程?

**有时取决于程序结构**

​	例如: 每个客户端一个线程, 后台任务一个线程

**有时出于对多核并行性的渴望**

​	所以每个核心有一个线程

​	Go 语言运行时在每个可用的核上自动调度运行 goroutine

**有时出于对I/O并发的渴望**

​	线程数量由容量和延迟决定

​	持续增长直到吞吐量停止增长

**Go 语言线程非常廉价**

​	100个或1000个线程都没问题, 但100万个不行

​	创建线程比调用方法成本高

## 线程的挑战
**共享数据**

一个线程读取另一个线程正在更改的数据

例如: 两个线程计数 count = count + 1

这是一个 "竞争" -- 是一个常见的 bug

- 使用 Mutexes (互斥) [ 或者 synchronization (同步) ]
- 或者避免恭喜

**两个线程间的协调**

如何等待所有的线程集合完成?

使用 Go 语言的 channel 或者 WaitGroup

**并发粒度**

粗粒度：简单, 但只能支持很少的并发/并行

细粒度：能带来更多的并发，也会带来更多的竞争和死锁

# 什么是爬虫?

- 目标是获取所有网页, 例如: 提供给索引器
- 网页图表
- 每个页面多个链接
- 图有循环

## 爬虫挑战

**编排并发I/O**

- 同时获取多个URL
- 增加每秒获取的URL
- 很大程度上网络延迟比网络容量大很多

**每个URL只获取一次**

- 避免浪费网络带宽
- 对远程服务器好一些
- =>需要记住访问了哪些URL

**知道什么时候结束**

**爬虫问题** [crawler.go 链接在 schedule 页面]

## 串行爬虫

- "fetched" 使用map 避免重复, 跳出循环
- 它是一个map, 通过引用进行递归调用
- 但是：一次只能抓取一个页面

## 并发互斥爬虫

**每提取一个页面创建一个线程**

- 并发抓取, 高抓取率

**这些线程共享 fetched map**

**为什么使用Mutex (== lock)?**

- **不使用锁**

  - 两个网页包含指向同一链接的URL
  - 两个线程同时获取这两个页面
  - T1检查 fetched[url], T2检查 fetched[url]
  - 两个线程都看到该URL没有被抓取
  - 两个线程都去抓取, 这是错误的

- **同时读写 (或 写 + 写) 是 “竞争”**

  - 通常表示一个bug
  - bug可能仅不幸的出现线程交错中

- **如果注释掉 Lock()/Unlock() 调用会发生什么?**

  - `go run crawler.go`
  - `go run -race crawler.go`

   锁让检查和更新是原子的

- **如何决定是否完成?**

  - `sync.WaitGroup`
  - 隐式的等待子级抓取完成

## 并发通道爬虫

- **Go Channel**
  - 一个channel是一个对象;  可能有很多 channel
    - `ch := make(chan int)`
  - channel 允许一个线程将对象发送到另一个线程
  - `ch <- x`
    - 发送方等待直到某个 goroutine 接收
  - `y := <- ch`
    - `for y := range ch`
    - 接收方等待直到某个 goroutine 发送
  - 因此你可以使用 channel 进行通信和同步
  - 多个线程可以在一个通道上发送和接收
  - 记得：发送方在接收方接收前阻塞
    - 在发送时持有锁可能很危险...
- **ConcurrentChannel master()**
  - master() 为每个提取的页面创建一个 worker goroutine
  - worker() 通过 channel 发送 URL 
    - 多个 worker 在一个 channel 上发送
  - master() 通过 channel 读取 URL
  - [diagram: master, channel, workers]
- **不需要为 fetched map 加锁, 因为它不是共享的**
- **是否有共享数据?**
  - Channel
  - 在 channel 上 发送 slices 和 string
  - 参数从 master() 传到 worker()

## 什么时候共享数据和使用锁, 而不是 channel?

- **大多数问题都可以使用以上两种方式中的任意一种解决**
- **最有意义的方式取决于程序员的思考**
  - 状态 -- sharing and  locks
  - 通信 -- channels
  - 等待事件 -- channels
- 使用 Go 的竞太检测器:
  - https://golang.org/doc/articles/race_detector.html
  - `go test -race`

# 远程过程调用 (RPC)

分布式系统中的关键部分; 所有的实验使用RPC

目标：使编写 client/server 通信更容易

**RPC 消息图**

  Client             Server
    request--->
       <---response

**RPC尝试模拟本地函数调用**

```go
Client:
	z = fn(x, y)

Server:
	fn(x, y) {
      compute
      return z
    }

Rarely this simple in practice...
```

**软件架构**

```shell
  client app         handlers
    stubs           dispatcher
   RPC lib           RPC lib
     net  ------------ net
```

## Go example

- **一个 key/value 存储服务器的小玩具 --** `Put(key,value), Get(key)->value`
- **使用 Go 的 RPC 库**
- **Common:**
  - 你需要为每个 RPC 类型定义 Args 参数和 Reply 结构
- **Client:**
  - `connect()`的 `Dial()` 创建到服务器的TCP连接
  - `Call()` 请求 RPC 库执行调用
    - 你指定服务函数名，参数，放置replay的位置
    - 库封装参数，发送请求，等待，解封响应
    - 一般你也有一个 `reply.Err` 来表示服务失败级别
- **Server:**
  - 

[原文](/distributed-systems/mit-6.824/lec02-rpc-and-threads.html)