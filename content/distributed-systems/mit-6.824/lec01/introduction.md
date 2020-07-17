---
title: Lecture 01 Introduction
author: "Soul Mate"
categories: ["MIT-6.824"]
date: 2019-04-01
url: "/distributed-systems/mit-6.824/lec01-introduction.html"
---


# 课前基础

- Google MapReduce Paper 阅读

# 带着以下问题去读

- What will likely limit the performance？

  什么限制了性能

- How does detailed design reduce effect of slow network?

  如何详细设计慢网络环境下的recuce effect

- How do they get good load balance?

  他们如何得到比较好的负载均衡

- What about fault tolerance?

  容错?

- Details of worker crash recovery?

  worker carsh如何恢复？

- Other failures/problems? 

  其他故障问题

  - What if the master gives two workers the same Map() task?

    如果master给两个worker相同的Map() task 怎么办？

  - What if the master gives two workers the same Reduce() task?

    如果master给两个worker相同的Reduct() task怎么办？

  - What if a single worker is very slow -- a "straggler"?

    如果一个worker 非常慢 -- 一个 “落伍者” 怎么办？

  - What if a worker computes incorrect output, due to broken h/w or s/w?

    如果worker 因为 h/w 或 s/w 损坏计算出错误的输出怎么办？

  - What if the master crashes?

    如果master carsh怎么办？

- For what applications *doesn't* MapReduce work well?

  哪些应用不适用于MapReduce？

- How might a real-world web company use MapReduce?

  显示世界中哪些公司使用MapReduct?

# MapReduce

Let's talk about MapReduce (MR) as a case study.

让我们来学习关于MapReduce (MR) 的案例.

MR is a good illustration of 6.824's main topics  and is the focus of Lab 1

MR 可以很好的说明 6.824的主题，并且第一个实验也聚焦于此.

- help you get up to speed on Go and distributed programming

  帮助你快速进入分布式编程

- first exposure to some fault tolerance  

  首先揭露一些容错

  - motivation for better fault tolerance in later labs

    为后续实验提供更好的容错能力

- motivating app for many papers

- popular distributed programming framework 

  流行的分布式编程框架

- many descendants frameworks 

  许多由此衍生的框架

## MapReduce overview

- context

  multi-hour computations on multi-terabyte data-sets.  e.g. analysis of graph structure of crawled web pages

  数小时计算大数据集合. 例如: 分析爬取的web页面图结构

  only practical with 1000s of computers.

  仅适用于1000多台计算机

  often not developed by distributed systems experts.

  通常不是分布式系统专家进行开发

  distribution can be very painful, e.g. coping with failure.

  分布式非常痛苦,  例如: 应对失败

- overall goal

  non-specialist programmers can easily split data processing over many servers with reasonable efficiency.

  普通程序员也可以简单的在多台服务器上高效的分割数据进行处理.

  programmer defines Map and Reduce functions sequential code; often fairly simple

  程序员只定义Map 和 Reduce 函数的代码; 通常非常简单

- MR runs the functions on 1000s of machines with huge inputsand hides details of distribution

  MR 在有大量输入的机器上运行这些函数, 并能很好的隐藏分布式的细节.

## Abstract view of MapReduce

```c
input is divided into M files

[diagram: maps generate rows of K-V pairs, reduces consume columns]

Input1 -> Map -> a,1 b,1 c,1

Input2 -> Map ->     b,1

Input3 -> Map -> a,1     c,1
                  |   |   |
                  |   |   -> Reduce -> c,2
                  |   -----> Reduce -> b,2
                  ---------> Reduce -> a,2
MR calls Map() for each input file, produces set of k2,v2
	"intermediate" data
    	each Map() call is a "task"

MR gathers all intermediate v2's for a given k2 and passes them to a Reduce call final output is set of <k2,v3> pairs from Reduce() stored in R output files

[diagram: MapReduce API -- map(k1, v1) -> list(k2, v2) reduce(k2, list(v2) -> list(k2, v3)]
```



**Example: word count**

```shell
input is thousands of text files
Map(k, v)
	split v into words
    for each word w
		emit(w, "1")
Reduce(k, v)
	emit(len(v))
```



## MapReduce hides many painful details

- starting s/w on servers

  启动服务器上的　s/w

- tracking which tasks are done

  追踪哪些任务完成了

- data movement

  数据传递

- recovering from failures

  故障恢复

## MapReduce scales well

N computers gets you Nx throughput.

N 台机器获得N倍的吞吐量

Assuming M and R are >= N (i.e., lots of input files and map output keys).　Maps()s can run in parallel, since they don't interact.　Same for Reduce()s.

如果M+R >= N , Maps()s 可以并行运行，直到它们之间不在进行交互． Reduce()s也是如此

The only interaction is via the "shuffle" in between maps and reduces.

maps 和reduces 之间唯一的交互来自"shuffle"

So you can get more throughput by buying more computers. Rather than special-purpose efficient parallelizations of each application.

所以你可以通过购买更多的计算机来获得更高的吞吐量．而不是每个程序自己并行化

Computers are cheaper than programmers!

电脑比程序员更便宜

## What will likely limit the performance

We care since that's the thing to optimize.

我们很关心这个问题,因为需要优化它.

CPU? memory? disk? network?

In 2004 authors were limited by "network cross-section bandwidth".
    [diagram: servers, tree of network switches]
    Note all data goes over network, during Map->Reduce shuffle.
    Paper's root switch: 100 to 200 gigabits/second
    1800 machines, so 55 megabits/second/machine.
    Small, e.g. much less than disk (~50-100 MB/s at the time) or RAM speed.
So they cared about minimizing movement of data over the network.
    (Datacenter networks are much faster today.)

## More details

master: gives tasks to workers; remembers where intermediate output is
M Map tasks, R Reduce tasks
input stored in GFS, 3 copies of each Map input file
all computers run both GFS and MR workers
many more input tasks than workers
master gives a Map task to each worker
    hands out new tasks as old ones finish
Map worker hashes intermediate keys into R partitions, on local disk
  Q: What's a good data structure for implementing this?
  no Reduce calls until all Maps are finished
  master tells Reducers to fetch intermediate data partitions from Map workers
  Reduce workers write final output to GFS (one file per Reduce task)

## Q&A

### How does detailed design reduce effect of slow network?

Map input is read from GFS replica on local disk, not over network.

map 输入从本地磁盘上的GFS副本读取, 不需要通过网络

Intermediate data goes over network just once.

中间数据只需要传输一次

Map worker writes to local disk, not GFS.

Map worker 不写到GFS上, 写到本地磁盘上

Intermediate data partitioned into files holding many keys.

中间数据被划分为包含多个key

Q: Why not stream the records to the reducer (via TCP) as they are being produced by the mappers?

​     为什么不在map生成数据流记录时通过TCP传递给reducer?

A: Map 会生成很多中间数据, 如果每次生成都要通过网络传输给 reducer的话,会造成很大的网络压力, 同时网络传输也会降低整个程序的性能.



###　How do they get good load balance?

Critical to scaling -- bad for N-1 servers to wait for 1 to finish.

But some tasks likely take longer than others.
[diagram: packing variable-length tasks into workers]

Solution: many more tasks than workers.
    Master hands out new tasks to workers who finish previous tasks.
    So no task is so big it dominates completion time (hopefully).
    So faster servers do more work than slower ones, finish abt the same time.

### What about fault tolerance?

I.e. what if a server crashes during a MR job?

​	如果MR工作时服务器崩溃怎么办？ 

Hiding failures is a huge part of ease of programming!

隐藏故障是使得编程容易的一个重要部分

Q: Why not re-start the whole job from the beginning?

　为什么不重新开始运行 job ?

MR re-runs just the failed Map()s and Reduce()s.

MR 只重新运行失败的Map()s 和　Reduce()s．

MR requires them to be pure functions:
MR 要求它们是纯函数：

​	they don't keep state across calls,
	它们不在调用中保持状态     

​	they don't read or write files other than expected MR inputs/outputs,
      	除了预期的MR 输入/输出外，它们不需要读写文件

​	there's no hidden communication among tasks.

​	它们在任务中没有隐藏掉的通信

So re-execution yields the same output.

因此重新执行也能产生相同的输出

The requirement for pure functions is a major limitation of　MR compared to other parallel programming schemes.　But it's critical to MR's simplicity.

与其他并行的方案相比，对纯函数要求是 MR的一个主要需求，但这也是MR 简单的关键．

### Details of worker crash recovery

- Map worker crashes:

  master sees worker no longer responds to pings

  crashed worker's intermediate Map output is lost but is likely needed by every Reduce task!

  master re-runs, spreads tasks over other GFS replicas of input.

  some Reduce workers may already have read failed worker's intermediate data.

  here we depend on functional and deterministic Map()!

  master need not re-run Map if Reduces have fetched all intermediate data

  though then a Reduce crash would then force re-execution of failed Map

- Reduce worker crashes.

  finshed tasks are OK -- stored in GFS, with replicas.

  master re-starts worker's unfinished tasks on other workers.

  Reduce worker crashes in the middle of writing its output.

- Reduce worker crashes in the middle of writing its output.

  GFS has atomic rename that prevents output from being visible until complete.

  so it's safe for the master to re-run the Reduce tasks somewhere else.

### Other failures/problems:

- What if the master gives two workers the same Map() task?

  perhaps the master incorrectly thinks one worker died.

  it will tell Reduce workers about only one of them.

- What if the master gives two workers the same Reduce() task?

  they will both try to write the same output file on GFS!

  atomic GFS rename prevents mixing; one complete file will be visible.

- What if a single worker is very slow -- a "straggler"?

  perhaps due to flakey hardware.

  master starts a second copy of last few tasks.

- What if a worker computes incorrect output, due to broken h/w or s/w?

  too bad! MR assumes "fail-stop" CPUs and software.

- What if the master crashes?

  recover from check-point, or give up on job

