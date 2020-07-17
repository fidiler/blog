---
title: Lecture 02 RPC and Threads
author: "Soul Mate"
categories: ["MIT-6.824"]
date: 2019-04-15
url: "/distributed-systems/mit-6.824/lec02-rpc-and-threads.html"
---


# Most commonly-asked question: Why Go?
**6.824 used C++ for many years**

C++ worked out well

but students spent time tracking down pointer and alloc/free bugs and there's no very satisfactory C++ RPC package

**Go is a bit better than C++ for us**

- good support for concurrency (goroutines, channels, &c)
- good support for RPC
- garbage-collected (no use after freeing problems)
- type safe
- threads + GC is particularly attractive!
  
**We like programming in Go**

relatively simple and traditional

After the tutorial, use https://golang.org/doc/effective_go.html Russ Cox will give a guest lecture March 8th

# Threads
threads are a useful structuring tool 

Go calls them goroutines; 

everyone else calls them threads 

they can be tricky

## Why threads?
They express concurrency, which shows up naturally in distributed systems I/O concurrency:

While waiting for a response from another server, process next request
Multicore: Threads run in parallel on several cores

## Thread = "thread of execution"
threads allow one program to (logically) execute many things at once

the threads share memory

each thread includes some per-thread state: program counter, registers, stack

## How many threads in a program?

**Sometimes driven by structure**

​	e.g. one thread per client, one for background tasks

**Sometimes driven by desire for multi-core parallelism**

​	so one active thread per core

​	the Go runtime automatically schedules runnable goroutines on available cores

**Sometimes driven by desire for I/O concurrency**

​	the number is determined by latency and capacity

​	keep increasing until throughput stops growing

**Go threads are pretty cheap**

​	100s or 1000s are fine, but maybe not millions

​	Creating a thread is more expensive than a method call

## Threading challenges:
**sharing data** 

​	one thread reads data that another thread is changing?

​	e.g. two threads do count = count + 1

​	this is a "race" -- and is usually a bug

​	-> use Mutexes (or other synchronization)

​	-> or avoid sharing

**coordination between threads**

​	how to wait for all Map threads to finish?

​	-> use Go channels or WaitGroup

**granularity of concurrency**

​	coarse-grained -> simple, but little concurrency/parallelism

​	fine-grained -> more concurrency, more races and deadlocks


## What is a crawler?
​	goal is to fetch all web pages, e.g. to feed to an indexer

​	web pages form a graph

​	multiple links to each page

​	graph has cycles

## Crawler challenges

**Arrange for I/O concurrency**

​	Fetch many URLs at the same time

​	To increase URLs fetched per second

​	Since network latency is much more of a limit than network capacity

**Fetch each URL only \*once\***

​	avoid wasting network bandwidth

​	 be nice to remote servers

​	=> Need to remember which URLs visited 

**Know when finished**

**Crawler solutions** [crawler.go link on schedule page]

## Serial crawler
the "fetched" map avoids repeats

breaks cycles it's a single map, passed by reference to recursive calls 

but: fetches only one page at a time

## ConcurrentMutex crawler:

**Creates a thread for each page fetch**

- Many concurrent fetches, higher fetch rate

**The threads share the fetched map**

**Why the Mutex (== lock)?**

-  **Without the lock:**
   -  Two web pages contain links to the same URL
   -  Two threads simultaneouly fetch those two pages
   -  T1 checks fetched[url], T2 checks fetched[url]
   -  Both see that url hasn't been fetched
   -  Both fetch, which is wrong

- **Simultaneous read and write (or write+write) is a "race"**
  - And often indicates a bug
  - The bug may show up only for unlucky thread interleavings
- **What will happen if I comment out the Lock()/Unlock() calls?**
  - go run crawler.go
  - go run -race crawler.go
- **The lock causes the check and update to be atomic**
- **How does it decide it is done?**
    - `sync.WaitGroup`
    - implicitly waits for children to finish recursive fetches

## ConcurrentChannel crawler

**a Go channel:**

- **a channel is an object; there can be many of them**
  - `ch := make(chan int)`
- **a channel lets one thread send an object to another thread**
- `ch <- x`
  - the sender waits until some goroutine receives
- `y := <- ch`
  - `for y := range ch`
  - a receiver waits until some goroutine sends
- **so you can use a channel to both communicate and synchronize**
- **several threads can send and receive on a channel**
- **remember: sender blocks until the receiver receives!**
  - may be dangerous to hold a lock while sending...

**ConcurrentChannel master()**

- **master() creates a worker goroutine to fetch each page**
- **worker() sends URLs on a channel**
  - multiple workers send on the single channel
- **master() reads URLs from the channel**
- [diagram: master, channel, workers]

**No need to lock the fetched map, because it isn't shared!**

**Is there any shared data?**

- The channel
- The slices and strings sent on the channel
- The arguments master() passes to worker() 

## When to use sharing and locks, versus channels?

**Most problems can be solved in either style**

**What makes the most sense depends on how the programmer thinks**

- state -- sharing and locks

- communication -- channels
- waiting for events -- channels

**Use Go's race detector:**

- https://golang.org/doc/articles/race_detector.html
- `go test -race` 


[参考译文](/distributed-systems/mit-6.824/lec02-rpc-and-threads-translate.html)