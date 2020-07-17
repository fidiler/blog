---
title: Lecture 01 Lab
author: "Soul Mate"
categories: ["MIT-6.824"]
date: 2019-04-12
url: "/distributed-systems/mit-6.824/lec01-lab.html"
---

# 6.824 Lab 1: MapReduce

## Introduction

In this lab you'll build a MapReduce library as an introduction to programming in Go and to building fault tolerant distributed systems. 

In the first part you will write a simple MapReduce program. 

In the second part you will write a Master that hands out tasks to MapReduce workers, and handles failures of workers. 

The interface to the library and the approach to fault tolerance is similar to the one described in the original [MapReduce paper](http://research.google.com/archive/mapreduce-osdi04.pdf).

**译文:**

在本实验中，你将构建一个 MapReduce 库作为 Go 语言和分布式容错的前导. 

在第一部分你将编写一个简单的 MapReduce 程序. 

在第二部分你将编写 Master 把任务分发给 worker, 并且处理 worker 的错误.

库的接口和容错途径与  [MapReduce paper ](http://research.google.com/archive/mapreduce-osdi04.pdf)描述的类似.

## Collaboration Policy

You must write all the code you hand in for 6.824, except for code that we give you as part of the assignment. 

You are not allowed to look at anyone else's solution, and you are not allowed to look at solutions from previous years.

You may discuss the assignments with other students, but you may not look at or copy each others' code. The reason for this rule is that we believe you will learn the most by designing and implementing your lab solution code yourself.  

Please do not publish your code or make it available to current or future 6.824 students. 

`github.com` repositories are public by default, so please don't put your code there unless you make the repository private. 

You may find it convenient to use [MIT's GitHub](https://github.mit.edu/), but be sure to create a private repository.  

**译文:** 

除了我们提供给你的部分代码, 你必须自己编写6.824的所有代码.

你不能查看他人的答案,也不能看前几年的答案.

你可以与其他同学讨论,但你不能查看或抄袭他人的代码.

制定这个规则的原因是因为我们相信你可以通过自己的设计和实现你的实验代码学到更多.

请不要提交你的代码或将它提供给当前或者以后的学习6.824课程的学生.

github.com 的仓库默认是公共的, 所以不要将你的代码放在那里, 除非你创建私有库.

你可能发现使用MIT's Github很方便, 但一定要创建一个私有库.

## Software

You'll implement this lab (and all the labs) in [Go](http://www.golang.org/). The Go web site contains lots of tutorial information which you may want to look at. We will grade your labs using Go version 1.9; you should use 1.9 too, though we don't know of any problems with other versions.  

The labs are designed to run on Athena Linux machines with x86 or x86_64 architecture; `uname -a` should mention `i386 GNU/Linux` or `i686 GNU/Linux` or `x86_64 GNU/Linux`. You can log into a public Athena host with `ssh athena.dialup.mit.edu`. You may get lucky and find that the labs work in other environments, for example on some laptop Linux or OSX installations.  

We supply you with parts of a MapReduce implementation that supports both distributed and non-distributed operation (just the boring bits). You'll fetch the initial lab software with [git](https://git-scm.com/) (a version control system). To learn more about git, look at the [Pro Git book](https://git-scm.com/book/en/v2) or the [git user's manual](http://www.kernel.org/pub/software/scm/git/docs/user-manual.html), or, if you are already familiar with other version control systems, you may find this [CS-oriented overview of git](http://eagain.net/articles/git-for-computer-scientists/) useful.  


These Athena commands will give you access to git and Go:  

```shell
athena$ add git
athena$ setup ggo_v1.9
```

The URL for the course git repository is `git://g.csail.mit.edu/6.824-golabs-2018`. To install the files in your directory, you need to *clone* the course repository, by running the commands below.  

```shell
$ git clone git://g.csail.mit.edu/6.824-golabs-2018 6.824
$ cd 6.824
$ ls
Makefile src
```

 Git allows you to keep track of the changes you make to the code. For example, if you want to checkpoint your progress, you can *commit* your changes by running: 

```shell
$ git commit -am 'partial solution to lab 1'
```

 The Map/Reduce implementation we give you has support for two modes of operation, **sequential** and **distributed**. In the former, the map and reduce tasks are executed one at a time: first, the first map task is executed to completion, then the second, then the third, etc. When all the map tasks have finished, the first reduce task is run, then the second, etc. This mode, while not very fast, is useful for debugging. The distributed mode runs many worker threads that first execute map tasks in parallel, and then reduce tasks. This is much faster, but also harder to implement and debug.  

**译文:** 

你将使用Go语言实现这个实验(和其他所有实验). Go的官网可能包含了一些你想要了解的信息. 我们将使用Go 1.9版本对你的实验进行评级. 我们不知道其他版本会有什么问题, 你也应该使用1.9版本. 

这个实验计划运行在Athena Linux x86 或 x86_64 架构的机器上; `uname -a` 应该能看到 `i386 GNU/Linux` or `i686 GNU/Linux` or `x86_64 GNU/Linux`.  你也可以使用 `ssh athena.dialup.mit.edu`地址 登录到公共的 Athena. 你可能会惊喜的发现实验可以在其他环境下工作, 例如一些laptop linux 或者 OSX.

我们提供给你MapReduce支持分布式和非分布式的部分的实现 (只是一些无聊的东西). 你可以使用git获得最初的实验软件.[git](https://git-scm.com/) (一个版本控制系统). 了解关于git的更多信息, 可以看 [Pro Git book](https://git-scm.com/book/en/v2) 或者是 [git user's manual](http://www.kernel.org/pub/software/scm/git/docs/user-manual.html), 再或者, 如果你已经熟悉其他版本控制系统, 你可能发现这个  [CS-oriented overview of git](http://eagain.net/articles/git-for-computer-scientists/) 非常有用.

这些 Athena 命令将允许你访问 git 和  Go: 

```shell
athena$ add git
athena$ setup ggo_v1.9
```



课程的 Git 仓库URL是 `git://g.csail.mit.edu/6.824-golabs-2018`. 要在你的目录中安装这些文件, 你需要 通过以下命令来 clone 这个课程的 Git 仓库

```shell
$ git clone git://g.csail.mit.edu/6.824-golabs-2018 6.824
$ cd 6.824
$ ls
Makefile src
```

Git 允许你追踪对代码的修改. 例如, 如果你想检查你的进度, 你可以通过运行以下命令提交修改: 

```shell
$ git commit -am 'partial solution to lab 1'
```

我们提供的Map/Reduce支持两种方式, **sequential** 和 **distributed**. 在前者中, map 和 reduce 一次执行一个: 首先, 第一个 map 任务执行完成, 然后是第二个, 然后是第三个, 等等. 当所有的 map 任务执行完成, 第一个 reduce 任务开始运行, 然后是第二个, 等等. 这个模式虽然不是很快, 但对调试比较有用. **distributed** 模式运行很多 worker 线程 , 它们首先并行执行map 任务, 然后是 reduce 任务. 这个模式快很多, 但是调试和实现比较困难.

## Preamble: Getting familiar with the source

The mapreduce package provides a simple Map/Reduce library (in the mapreduce directory). Applications should normally call Distributed() [located in master.go] to start a job, but may instead call Sequential() [also in master.go] to get a sequential execution for debugging.  

The code executes a job as follows: 

1. The application provides a number of input files, a map function, a reduce function, and the number of reduce tasks (`nReduce`). 

2. A master is created with this knowledge. It starts an RPC server (see `master_rpc.go`), and waits for workers to register (using the RPC call `Register()` [defined in `master.go`]). As tasks become available (in steps 4 and 5), `schedule()` [`schedule.go`] decides how to assign those tasks to workers, and how to handle worker failures. 

3. The master considers each input file to be one map task, and calls `doMap()` [`common_map.go`] at least once for each map task. It does so either directly (when using `Sequential()`) or by issuing the `DoTask` RPC to a worker [`worker.go`]. Each call to `doMap()` reads the appropriate file, calls the map function on that file's contents, and writes the resulting key/value pairs to `nReduce` intermediate files. `doMap()` hashes each key to pick the intermediate file and thus the reduce task that will process the key. There will be `nMap` x `nReduce` files after all map tasks are done. Each file name contains a prefix, the map task number, and the reduce task number. If there are two map tasks and three reduce tasks, the map tasks will create these six intermediate files: 

   ```shell
   mrtmp.xxx-0-0
   mrtmp.xxx-0-1
   mrtmp.xxx-0-2
   mrtmp.xxx-1-0
   mrtmp.xxx-1-1
   mrtmp.xxx-1-2
   ```

   Each worker must be able to read files written by any other worker, as well as the input files. Real deployments use distributed storage systems such as GFS to allow this access even though workers run on different machines. In this lab you'll run all the workers on the same machine, and use the local file system. 

4. The master next calls `doReduce()` [`common_reduce.go`] at least once for each reduce task.  As with `doMap()`, it does so either directly or through a worker. The `doReduce()` for reduce task `r` collects the `r`'th intermediate file from each map task, and calls the reduce function for each key that appears in those files. The reduce tasks produce `nReduce` result files. 

5. The master calls `mr.merge()` [`master_splitmerge.go`], which merges all the `nReduce` files produced by the previous step into a single output. 

6. The master sends a Shutdown RPC to each of its workers, and then shuts down its own RPC server. 

> **Notes:** 
>
> Over the course of the following exercises, you will have to write/modify `doMap`, `doReduce`, and `schedule` yourself. These are located in `common_map.go`, `common_reduce.go`, and `schedule.go` respectively. You will also have to write the map and reduce functions in `../main/wc.go`.

You should not need to modify any other files, but reading them might be useful in order to understand how the other methods fit into the overall architecture of the system. 



**译文:** 

mapreduce 包提供了一个简单的Map/Reduce库(在mapreduce目录). 应用一般调用 `Distributed()` [在master.go] 去启动一个任务, 但也可以调用 `Sequential()` 替代 [也在master.go] 以获取便于调试的顺序执行.

代码执行流程:

1. 应用提供许多输入文件, 一个 map 函数, 一个 reduce 函数以及 reduce 任务的数量 (`nReduce`)

2. master使用此方式创建. 它启动一个RPC服务 (详见 `master_rpc.go`),  并等待 wrokers 注册 (使用RPC调用`Register()` [定义在 `master.go` 中]). 当任务可用时 (在步骤4和5中),  `schedule()` [`schedule.go`] 决定如何给 workers 分配这些任务, 以及如何处理 worker 失败.

3. master将每个输入文件都视为一个 map 任务, 并为每个 map 任务都至少调用一次 `doMap()`[`common_map.go`] .  每次调用 `doMap()` 都会读取相应的文件, 并在该文件内容上调用 map 函数, 以及将生成的 key/value 对写入 `nReduce` 中间文件. `doMap()` 哈希通过每个key选择一个中间文件,  于是reduce 任务将处理这个key. 所有 map 任务处理完成后将出现 `nMap` × `nReduce` 个文件.  每个文件都包含一个前缀, map 任务号, reduce任务号.  如果有两个 map 任务和三个 reduce 任务, map 任务将创建6个中间文件:

   ```shell
   mrtmp.xxx-0-0
   mrtmp.xxx-0-1
   mrtmp.xxx-0-2
   mrtmp.xxx-1-0
   mrtmp.xxx-1-1
   mrtmp.xxx-1-2
   ```

每个 worker 都必须能够读取其他任意 worker 写入的文件, 以及输入的文件. 实际部署使用分布式存储系统(类似GFS) 来允许这种访问, 即使 worker 在不同的机器上运行. 在这个实验中, 你将在同一台机器上运行所有的 worker, 并使用本地文件系统. 

1. 下一步, master 至少为每个 reduce 任务调用一次 `doReduce()`[`common_reduce.go`]. 与 `doMap()` 一样,  它可以直接运行或者通过 worker 运行. 用于 reduce 任务 的 `doReduce()` `r` 从 每个map任务收集第 `r`个中间文件. 并为这些文件中出现的每个 key 调用 reduce 函数.  reduce 任务生成 `nReduce` 结果文件.
2. master 调用 `mr.merge()` [`master_splitmerge.go`], 将上一步生成的所有 `nReduce` 文件合并为一个单独的输出.
3. master 向每个worker 发送关闭RPC, 然后关闭自己的RPC 服务器.

> **Notes:** 
>
> 在以下练习中, 你必须自己编写 `doMap`, `doReduce` 和 `schedule`. 它们分别位于 `common_map.go`, `common_reduce.go`, 和 `schedule.go` . 你还必须在 `../main/wc.go` 编写 map 和 reduce 函数.

你不需要修改其他任何的文件, 但是阅读它们可能对于理解其他方法和适应总体系统架构是有用的.



## Part I: Map/Reduce input and output

The Map/Reduce implementation you are given is missing some pieces. Before you can write your first Map/Reduce function pair, you will need to fix the sequential implementation. In particular, the code we give you is missing two crucial pieces: the function that divides up the output of a map task, and the function that gathers all the inputs for a reduce task. These tasks are carried out by the `doMap()` function in `common_map.go`, and the `doReduce()` function in `common_reduce.go`respectively. The comments in those files should point you in the right direction.

To help you determine if you have correctly implemented `doMap()` and `doReduce()`, we have provided you with a Go test suite that checks the correctness of your implementation. These tests are implemented in the file `test_test.go`. To run the tests for the sequential implementation that you have now fixed, run:

```shell
$ cd 6.824
$ export "GOPATH=$PWD"  # go needs $GOPATH to be set to the project's working directory
$ cd "$GOPATH/src/mapreduce"
$ go test -run Sequential
ok  	mapreduce	2.694s
```

> **TASK:**  
>
> You receive full credit for this part if your software passes the Sequential tests (as run by the command above) when we run your software on our machines.

 If the output did not show *ok* next to the tests, your implementation has a bug in it. To give more verbose output, set `debugEnabled = true` in `common.go`, and add `-v` to the test command above. You will get much more output along the lines of:

```shell
$ env "GOPATH=$PWD/../../" go test -v -run Sequential
=== RUN   TestSequentialSingle
master: Starting Map/Reduce task test
Merge: read mrtmp.test-res-0
master: Map/Reduce task completed
--- PASS: TestSequentialSingle (1.34s)
=== RUN   TestSequentialMany
master: Starting Map/Reduce task test
Merge: read mrtmp.test-res-0
Merge: read mrtmp.test-res-1
Merge: read mrtmp.test-res-2
master: Map/Reduce task completed
--- PASS: TestSequentialMany (1.33s)
PASS
ok  	mapreduce	2.672s
```

**译文:** 

给你的 Map/Reduce 实现缺少一些片段. 在编写第一个 Map/Reduce 函数之前, 需要修复 sequential 的实现. 注意,  给你的代码缺少两个关键的部分: 划分输出的 map 函数,  收集所有输入的 reduce 函数. 这些任务分别由 `common_map.go` 中的 `doMap()` 函数和 `common_reduce.go` 中的 `doReduce()` 函数执行.  文件中的注释应该可以帮你搞清楚.

为了帮助你确定是否正确实现了 `doMap()` 和 `doReduce()`, 我们为你提供了一个Go 测试套件帮助你快速检查实现是否正确. 这些测试在 `test_test.go` 中实现. 运行你以及修复好的 sequential 测试, 请运行: 

```shell
$ cd 6.824
$ export "GOPATH=$PWD"  # go needs $GOPATH to be set to the project's working directory
$ cd "$GOPATH/src/mapreduce"
$ go test -run Sequential
ok  	mapreduce	2.694s
```

如果测试输出没有显示 *ok*, 说明你的实现存在bug. 为了查看更详细的输出, 在`command_go`中设置 `debugEnabl = true` , 并位上面的测试命令添加 `-v`. 你将获得更多的输出.


## Part II: Single-worker word count

Now you will implement word count — a simple Map/Reduce example. Look in `main/wc.go`; you'll find empty `mapF()` and `reduceF()` functions. Your job is to insert code so that `wc.go` reports the number of occurrences of each word in its input. A word is any contiguous sequence of letters, as determined by [`unicode.IsLetter`](http://golang.org/pkg/unicode/#IsLetter).

There are some input files with pathnames of the form `pg-*.txt` in ~/6.824/src/main, downloaded from [Project Gutenberg](https://www.gutenberg.org/ebooks/search/%3Fsort_order%3Ddownloads). Here's how to run `wc` with the input files:

```shell
$ cd 6.824
$ export "GOPATH=$PWD"
$ cd "$GOPATH/src/main"
$ go run wc.go master sequential pg-*.txt
# command-line-arguments
./wc.go:14: missing return at end of function
./wc.go:21: missing return at end of function
```

The compilation fails because `mapF()` and `reduceF()` are not complete.

Review Section 2 of the [MapReduce paper](http://research.google.com/archive/mapreduce-osdi04.pdf). Your `mapF()` and `reduceF()` functions will differ a bit from those in the paper's Section 2.1. Your `mapF()` will be passed the name of a file, as well as that file's contents; it should split the contents into words, and return a Go slice of `mapreduce.KeyValue`. While you can choose what to put in the keys and values for the `mapF` output, for word count it only makes sense to use words as the keys. Your `reduceF()` will be called once for each key, with a slice of all the values generated by `mapF()` for that key. It must return a string containing the total number of occurences of the key.

> - Hint: a good read on Go strings is the [Go Blog on strings](http://blog.golang.org/strings).
>
> - Hint: you can use [`strings.FieldsFunc`](http://golang.org/pkg/strings/#FieldsFunc) to split a string into components.
> - Hint: the strconv package (<http://golang.org/pkg/strconv/>) is handy to convert strings to integers etc.

You can test your solution using:

```shell
$ cd "$GOPATH/src/main"
$ time go run wc.go master sequential pg-*.txt
master: Starting Map/Reduce task wcseq
Merge: read mrtmp.wcseq-res-0
Merge: read mrtmp.wcseq-res-1
Merge: read mrtmp.wcseq-res-2
master: Map/Reduce task completed
2.59user 1.08system 0:02.81elapsed
```

The output will be in the file "mrtmp.wcseq". Your implementation is correct if the following command produces the output shown here:

 ```shell
$ sort -n -k2 mrtmp.wcseq | tail -10
that: 7871
it: 7987
in: 8415
was: 8578
a: 13382
of: 13536
I: 14296
to: 16079
and: 23612
the: 29748
 ```

You can remove the output file and all intermediate files with:

```shell
$ rm mrtmp.*
```

To make testing easy for you, run:

```shell
$ bash ./test-wc.sh
```

and it will report if your solution is correct or not.

> **TASK:**  
>
> You receive full credit for this part if your Map/Reduce word count output matches the correct output for the sequential execution above when we run your software on our machines.

**译文:**

现在你将实现一个简单的单词计数 — 一个简单的Map/Reduce 例子. 查看 `main/wc.go`; 你将会发现空的  `mapF()` 和 `reduceF()` 函数.  你的任务是在这两个函数中插入代码, 让 wc.go 报告输入中的每个单词的出现次数.

单词是任何连续的字符序列,  可以使用 [`unicode.IsLetter`](https://golang.org/pkg/unicode/#IsLetter) 函数来判定.

在 ~/6.824/src/main 有一些输入文件路径名是 `pg-*.txt`, 从 [Project Gutenberg](https://www.gutenberg.org/ebooks/search/%3Fsort_order%3Ddownloads)下载. 下面是如何输入文件运行 `wc`:

```shell
$ cd 6.824
$ export "GOPATH=$PWD"
$ cd "$GOPATH/src/main"
$ go run wc.go master sequential pg-*.txt
# command-line-arguments
./wc.go:14: missing return at end of function
./wc.go:21: missing return at end of function
```

这里编译失败是因为 `mapF()` 和 `reduceF()` 函数不是完整的. 

查看 [MapReduce paper](http://research.google.com/archive/mapreduce-osdi04.pdf) 中的第二节.  你的 `mapF()` 和 `reduceF()` 函数与论文2.1节有点不同. 你的 `mapF()`将传递文件名以及文件内容; 它应该把内容分为单词, 并且返回`mapreduce.KeyValue` 格式的 Go slice. 虽然你可以选择在 `mapF()` 输出的key  和 value中填入什么, 但对于单词计数来说, 使用单词作为 key 是有意义的. 每个 key 都会调用你的 `reduceF()`, 其中包括 `mapF()` 根据 key 生成的 value slice. 它必须返回一个字符串, 字符串中包含单词出现的总数.

>提示:  一个好的阅读Go字符串的文章 [Go Blog on strings](http://blog.golang.org/strings).
>
>提示:  你可以使用 [`strings.FieldsFunc`](http://golang.org/pkg/strings/#FieldsFunc) 将字符串拆分
>
>提示: strconv package (<http://golang.org/pkg/strconv/>)  便于将string 转换为 integer 等.

你可以使用下面的方式测试你的答案:

```shell
$ cd "$GOPATH/src/main"
$ time go run wc.go master sequential pg-*.txt
master: Starting Map/Reduce task wcseq
Merge: read mrtmp.wcseq-res-0
Merge: read mrtmp.wcseq-res-1
Merge: read mrtmp.wcseq-res-2
master: Map/Reduce task completed
2.59user 1.08system 0:02.81elapsed
```

输出将在 "mrtmp.wcseq" 文件中. 如果使用小面命令后生成如下的输出, 你的实现是正确的.

```shell
$ sort -n -k2 mrtmp.wcseq | tail -10
that: 7871
it: 7987
in: 8415
was: 8578
a: 13382
of: 13536
I: 14296
to: 16079
and: 23612
the: 29748
```

可以使用下面的命令删除输出文件和所有中间文件:

```shell
$ rm mrtmp.*
```

也可以更容易的运行测试:

```shell
$ bash ./test-wc.sh
```

运行后会告诉你的答案是否正确.

>**TASK:**
>
>如果我们在我们的机器上运行你的软件时，如果你的Map / Reduce word count 输出与上面执行的输出相匹配，那么你将获得此部分的全部学分



##  Part III: Distributing MapReduce tasks

Your current implementation runs the map and reduce tasks one at a time. One of Map/Reduce's biggest selling points is that it can automatically parallelize ordinary sequential code without any extra work by the developer. In this part of the lab, you will complete a version of MapReduce that splits the work over a set of worker threads that run in parallel on multiple cores. While not distributed across multiple machines as in real Map/Reduce deployments, your implementation will use RPC to simulate distributed computation.

The code in `mapreduce/master.go` does most of the work of managing a MapReduce job. We also supply you with the complete code for a worker thread, in `mapreduce/worker.go`, as well as some code to deal with RPC in `mapreduce/common_rpc.go`.

Your job is to implement `schedule()` in `mapreduce/schedule.go`. The master calls `schedule()`twice during a MapReduce job, once for the Map phase, and once for the Reduce phase. `schedule()`'s job is to hand out tasks to the available workers. There will usually be more tasks than worker threads, so `schedule()` must give each worker a sequence of tasks, one at a time.`schedule()` should wait until all tasks have completed, and then return.

`schedule()` learns about the set of workers by reading its `registerChan` argument. That channel yields a string for each worker, containing the worker's RPC address. Some workers may exist before `schedule()` is called, and some may start while `schedule()` is running; all will appear on`registerChan`. `schedule()` should use all the workers, including ones that appear after it starts.

`schedule()` tells a worker to execute a task by sending a `Worker.DoTask` RPC to the worker. This RPC's arguments are defined by `DoTaskArgs` in `mapreduce/common_rpc.go`. The `File` element is only used by Map tasks, and is the name of the file to read; `schedule()` can find these file names in `mapFiles`.

Use the `call()` function in `mapreduce/common_rpc.go` to send an RPC to a worker. The first argument is the the worker's address, as read from `registerChan`. The second argument should be `"Worker.DoTask"`. The third argument should be the `DoTaskArgs` structure, and the last argument should be `nil`.

Your solution to Part III should only involve modifications to `schedule.go`. If you modify other files as part of debugging, please restore their original contents and then test before submitting.

Use `go test -run TestParallel` to test your solution. This will execute two tests, `TestParallelBasic` and `TestParallelCheck`; the latter verifies that your scheduler causes workers to execute tasks in parallel.

> **TASK:**  
>
> You will receive full credit for this part if your software passes`TestParallelBasic` and `TestParallelCheck` when we run your software on our machines.



>- Hint: [RPC package](https://golang.org/pkg/net/rpc/) documents the Go RPC package.
>- Hint: `schedule()` should send RPCs to the workers in parallel so that the workers can work on tasks concurrently. You will find the `go` statement useful for this purpose; see[Concurrency in Go](http://golang.org/doc/effective_go.html#concurrency).
>- Hint: `schedule()` must wait for a worker to finish before it can give it another task. You may find Go's channels useful.
>- Hint: You may find [sync.WaitGroup](https://golang.org/pkg/sync/#WaitGroup) useful.
>- Hint: The easiest way to track down bugs is to insert print statements (perhaps calling `debug()` in `common.go`), collect the output in a file with `go test -run TestParallel > out`, and then think about whether the output matches your understanding of how your code should behave. The last step is the most important.
>- Hint: To check if your code has race conditions, run Go's [race detector](https://golang.org/doc/articles/race_detector.html) with your test: `go test -race -run TestParallel > out`.



> **Note:** 
>
>  The code we give you runs the workers as threads within a single UNIX process, and can exploit multiple cores on a single machine. Some modifications would be needed in order to run the workers on multiple machines communicating over a network. The RPCs would have to use TCP rather than UNIX-domain sockets; there would need to be a way to start worker processes on all the machines; and all the machines would have to share storage through some kind of network file system.

**译文:**

你当前实现的map 和 reduce 任务一次只能运行一个. Map/Reduce’s 最大的卖点之一就是开发者不需要做额外的工作就可以让普通的顺序代码自动的并行运行.  在这部分的实现中,  你会完成拆分任务到一组并行运行在多核上 worker 线程的 MapReduce 版本. 虽然不想真正的 Map/Reduce 那样部署在多台机器上,  你的实现可以使用 RPC 来模拟分布式计算.

`mapreduce/master.go` 中的代码完成了大部分管理 MapReduce 的工作. 在 `mapreduce/worker.go` 中, 我们还为你提供了一个完成的 worker 线程代码,  以及一些在 `mapreduce/common_rpc.go`  中处理 RPC的代码. 

你的工作是实现 `mapreduce/schedule.go` 中的 `schedule()`.  master 在 MapReduce 工作期间调用 `schedule()` 两次, 一次是 Map 阶段, 一次是 Reduce 阶段.  `schedule()` 的工作是将任务分发给可用的 worker.  通常任务会多余 worker 线程, 因此 `schedule()` 必须给予每个 worker 一个 任务顺序, 一次一个. ``schedule`()` 应该等待所有任务完成, 然后返回.

`schedule()` 通过向 worker 发送 `Worker.DoTask` RPC 来通知其执行任务. RPC的参数定义在 `mapreduce/common_rpc.go` 中的 `DoTaskArgs` 结构体中.`DoTaskArgs中的` `File`参数仅用在 Map 任务中,  是要读取文件的名称; `schedule()` 能够在 `mapFiles` 中发现这些文件名.

使用 `mapreduce/common_rpc.go` 中的 `call()` 函数给 worker 发送 RPC. `call()` 的第一个参数是 worker 的地址， 通过读取 `registerChan` 可以得到. 第二个参数应该是 `"Worker.DoTask"`. 第三个参数应该是 `DoTaskArgs` 结构体, 最后一个参数应该是 `nil`.

你对第三部分的答案应该仅限修改 `schedule.go`. 如果你 debug 的时候修改了其他文件, 请恢复的内容, 并通过测试后提交.

运行 `go test -run TestParallel` 测试你的答案. 该命令会执行两个测试, `TestParallelBasic` 和 `TestParallelCheck`; 后者验证你的 schedule 可以让 worker 并行执行任务.

>**TASK:**
>
>当在我们的机器上运行你的软件时，如果你的软件通过了 `TestParallelBasic` and `TestParallelCheck`测试，你将获得所有学分.
>
>- 提示：Go  RPC 包文档 [RPC package](https://golang.org/pkg/net/rpc/)
>- 提示：`schedule()`应该将 RPC 并行发送给 worker, 因此 worker 可以并发执行任务.  你会发现 `go` 语法对此很有用; 可以看 [Concurrency in Go](http://golang.org/doc/effective_go.html#concurrency).
>- 提示：`schedule()`必须等待一个 worker 结束后才能调度其他任务.  你会发现 Go的 channels 很有用.
>- 提示：你会发现 [sync.WaitGroup](https://golang.org/pkg/sync/#WaitGroup) 应该会有帮助.
>- 提示：查找错误最简单的方法是插入 print 语句 ( 或许调用 `common.go` 中的 `debug()` ), 可以运行 `go test -run TestParallel > out` 来收集输出到一个文件中,  然后考虑输出是否符合你对代码执行的理解. 最后一步是非常重要的.
>- 提示：检查你的代码是否有竞争条件，在你的测试运行 Go 的[race detector](https://golang.org/doc/articles/race_detector.html)： `go test -race -run TestParallel > out`.
>
>**Note:**
>
>我给提供给你的代码运行在单个UNIX进程中以线程的方式运行, 可以在一个机器上利用多核. 为了在多台通信的机器上运行 worker, 需要做一些修改.  RPC 必须使用 TCP 而不是 UNIX-domain socket; 需要一种方法来启动所有机器上的 worker 进程; 所有的机器通过某种网络存储系统共享存储.

## Part IV: Handling worker failures

In this part you will make the master handle failed workers. MapReduce makes this relatively easy because workers don't have persistent state. If a worker fails while handling an RPC from the master, the master's call() will eventually return `false` due to a timeout. In that situation, the master should re-assign the task given to the failed worker to another worker.

An RPC failure doesn't necessarily mean that the worker didn't execute the task; the worker may have executed it but the reply was lost, or the worker may still be executing but the master's RPC timed out. Thus, it may happen that two workers receive the same task, compute it, and generate output. Two invocations of a map or reduce function are required to generate the same output for a given input (i.e. the map and reduce functions are "functional"), so there won't be inconsistencies if subsequent processing sometimes reads one output and sometimes the other. In addition, the MapReduce framework ensures that map and reduce function output appears atomically: the output file will either not exist, or will contain the entire output of a single execution of the map or reduce function (the lab code doesn't actually implement this, but instead only fails workers at the end of a task, so there aren't concurrent executions of a task).

> **Note:**
>
> You don't have to handle failures of the master. Making the master fault-tolerant is more difficult because it keeps state that would have to be recovered in order to resume operations after a master failure. Much of the later labs are devoted to this challenge.

Your implementation must pass the two remaining test cases in `test_test.go`. The first case tests the failure of one worker, while the second test case tests handling of many failures of workers. Periodically, the test cases start new workers that the master can use to make forward progress, but these workers fail after handling a few tasks. To run these tests:

```shell
go test -run Failure
```

> **TASK:** 
>
> You receive full credit for this part if your software passes the tests with worker failures (those run by the command above) when we run your software on our machines.

 Your solution to Part IV should only involve modifications to `schedule.go`. If you modify other files as part of debugging, please restore their original contents and then test before submitting.

**译文:**

在这一部分, 你将使 master 去处理失败的 worker. MapReduce 使得这部分的工作容易, 因为 woker 没有持久状态. 如果 worker 处理来自 master 的 RPC 时失败,  会造成 master 的 call() 调用超时最终返回false. 在这种情况下, master 应该将失败的 worker 任务重新分配给另外一个 worker.

RPC 失败并不意味着worker没有执行工作; worker 可能已经执行了, 但是回复丢失了, 或者是worker正在执行,但是master RPC 超时. 因此, 可能有两个worker接收到相同的任务, 计算并产生输出. map 或 reduce 函数需要为一个给定输入的两次调用产生相同的输出. (即 map 和 reduce 函数是 "函数式的"),  因此, 如果后续的处理一会读取一个输出,一会又读取另一个输出, 就会不一致. 另外, MapReduce 框架确保map 和 reduce 函数的输出是原子的: 文件要么不存在, 要么将包含一次执行的map 或  reduce 函数的整体输出. (实验代码实际上没有实现这一点, 而是仅仅在任务结束时工人才失败, 因此不存在任务的并发执行).

> **Note:**
>
> 你不用处理master的失败. master的容错处理更加困难, 因为它保留了master故障后为了恢复的状态. 后续的许多实现都会致力于解决这一问题.

你的实现需要通过 `test_test.go` 剩余的两个测试用例. 第一个案例测试一个worker失败的情况, 而第二个案例则测试许多worker失败的情况.  测试用例会定期的启动新的 worker, master 可以使用这些worker 来推进进度, 但这 些 worker 处理完一些任务后会失败. 运行这些测试

```shell
go test -run Failure
```

>**TASK:**
>
>当在我们机器上运行你的软件时, 如果你的通过了带有 worker 故障的所有测试 (上面的那些命令), 你将获得这部分的全部学分.

## Part V: Inverted index generation (optional, does not count in grade)

For this optional no-credit exercise, you will build Map and Reduce functions for generating an *inverted index*.

Inverted indices are widely used in computer science, and are particularly useful in document searching. Broadly speaking, an inverted index is a map from interesting facts about the underlying data, to the original location of that data. For example, in the context of search, it might be a map from keywords to documents that contain those words.

We have created a second binary in `main/ii.go` that is very similar to the `wc.go` you built earlier. You should modify `mapF` and `reduceF` in `main/ii.go` so that they together produce an inverted index. Running `ii.go` should output a list of tuples, one per line, in the following format:

```shell
$ go run ii.go master sequential pg-*.txt
$ head -n5 mrtmp.iiseq
A: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
ABOUT: 1 pg-tom_sawyer.txt
ACT: 1 pg-being_ernest.txt
ACTRESS: 1 pg-dorian_gray.txt
ACTUAL: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
```

If it is not clear from the listing above, the format is:

```shell
word: #documents documents,sorted,and,separated,by,commas
```

 You can see if your solution works using `bash ./test-ii.sh`, which runs: 

```shell
$ LC_ALL=C sort -k1,1 mrtmp.iiseq | sort -snk2,2 | grep -v '16' | tail -10
www: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
year: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
years: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
yesterday: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
yet: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
you: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
young: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
your: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
yourself: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
zip: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
```

**译文:**

这个部分的练习是可选的，不计入学分, 你将构建一个生成反向索引的 Map 和 Reduce 函数.

反向索引广泛应用在计算机科学，特别是文档搜索. 一般来讲, 反向索引是关于底层数据部分片段到该数据原始位置的映射. 例如，在搜索引文本中，它可能是从关键词到这些词文档的映射. 

我们在 `main/ii.go` 中创建了第二个可执行文件,它与 你之前构建的`wc.go` 非常类似. 你应该在 `main/ii.go` 中修改 `mapF` 和 `reduceF`, 它们可以一起生成反向索引. 运行 `ii.go` 应该会输出一个 元组列表，每行一个，格式如下：

```shell
$ go run ii.go master sequential pg-*.txt
$ head -n5 mrtmp.iiseq
A: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
ABOUT: 1 pg-tom_sawyer.txt
ACT: 1 pg-being_ernest.txt
ACTRESS: 1 pg-dorian_gray.txt
ACTUAL: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
```

如果上面说的不是很清楚，请看下面：

```shell
word: #documents documents,sorted,and,separated,by,commas
```

你可以使用 `bash ./test-ii.sh` 查看你的答案是否正确, 运行:

```shell
$ LC_ALL=C sort -k1,1 mrtmp.iiseq | sort -snk2,2 | grep -v '16' | tail -10
www: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
year: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
years: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
yesterday: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
yet: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
you: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
young: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
your: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
yourself: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
zip: 8 pg-being_ernest.txt,pg-dorian_gray.txt,pg-frankenstein.txt,pg-grimm.txt,pg-huckleberry_finn.txt,pg-metamorphosis.txt,pg-sherlock_holmes.txt,pg-tom_sawyer.txt
```



##  Running all tests

You can run all the tests by running the script `src/main/test-mr.sh`. With a correct solution, your output should resemble:

```shell
$ bash ./test-mr.sh
==> Part I
ok  	mapreduce	2.053s

==> Part II
Passed test

==> Part III
ok  	mapreduce	1.851s

==> Part IV
ok  	mapreduce	10.650s

==> Part V (inverted index)
Passed test
```

**译文:**

你可以通过 `src/main/test-mr.sh` 这个脚本运行所有的测试.  如果答案正确, 你的输出应该是:

```shell
$ bash ./test-mr.sh
==> Part I
ok  	mapreduce	2.053s

==> Part II
Passed test

==> Part III
ok  	mapreduce	1.851s

==> Part IV
ok  	mapreduce	10.650s

==> Part V (inverted index)
Passed test
```

