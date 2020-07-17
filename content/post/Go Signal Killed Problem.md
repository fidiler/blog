---
title: "Go 中碰到的Signal killed问题"
date: "2020-06-29"
categories: ["Golang"]
tags: ["Golang", "OOM"]
---

# 背景

今天照常写完代码，运行go的测试用例的时候，出现了`signal killed`。很自然的，go 进程被杀死，测试终止。

我这段测试代码是测试` Kuhn－Munkre ` 算法 ，算法是cgo混编的，用于做乘客订单和车辆的二分匹配。测试代码用于验证匹配结果。

机器是基于我本地的 `Virtualbox Ubuntu 18.04LTS` 的虚拟机，虚拟机内存2GB。

测试用例测试10000个订单和20辆车匹配，因此心里快速估算了一下运行过程中会产生如下的内存开销：

- Go 程序内部首先会有10000个订单的状态，在调用c++部分的代码执行算法计算的时候，会将矩阵压缩为一个10000 * 10000一维数组，通过cgo的机制传递给c++程序

  ```go
  // go 部分
  cArray := make([]float64, max_v_num*max_v_num) // 10000 * 10000
  result := C.entrance((*C.double)(unsafe.Pointer(&cArray[0])), C.long(max_v_num)) // cgo调用
  ```

  

- C++部分代码会生成 10000 * 10000 的矩阵，同时会初始化多个10000大小的数组

  ```c++
  // c++ 部分
  
  // 矩阵初始化 10000 * 10000
  weight = new double*[input_max_v_num];
  for(int i=0;i<input_max_v_num;i++){
      weight[i] = new double[input_max_v_num];
  }
  
  // 其他km辅助遍历初始化 10000
  max_v_num = input_max_v_num;
  lx = new double[max_v_num];
  ly = new double[max_v_num];
  slack = new double[max_v_num];
  x_used = new bool[max_v_num];
  y_used = new bool[max_v_num];
  linkx = new long[max_v_num]; 
  linky = new long[max_v_num]; 
  before = new long[max_v_num];
  ```

# CGO内存模型

考虑到CGO的特殊性，在排查问题的时候深入的思考了我代码中CGO部分的内存模型。

go和c/c++程序之间调用是通过二进制接口（ABI）完成的。ABI标准涵盖了很多细节，例如：

- 数据类型大小，数据的内存布局和对齐
- 调用约定， 例如，是所有的参数都通过栈传递，还是部分参数通过寄存器传递；哪个寄存器用于哪个函数参数；通过栈传递的第一个函数参数是最先push到栈上还是最后； 
- 系统调用的编码和一个应用如何向操作系统进行系统调用
- 目标文件的二进制格式
- ......

通常是操作系统或编译器的开发者来觉得是否可以与其他语言进行ABI交互，很显然go语言的开发者实现了cgo之间的ABI交互。

## go和c之间的内存布局不同

go有自己的内存分配和回收机制，这部分完全由go的runtime去控制的，也就是说go的内存地址在运行过程中会变化，例如goroutine的栈伸缩的时候。

c一般会有内存分配器（例如malloc、tcmalloc），内存分配器决定如何去分配地址，但内存分配之后就是固定的地址，如果申请者不手动释放，则程序运行过程中内存会一直存在，也就是说c的内存地址是稳定的。

## go持有c分配的内存地址

看过go slice 部分源码的同学应该知道，slice 无法分配一个超过2GB内存的空间 (`makeslice` ) ，但如果使用cgo编程，我们知道C的内存地址是稳定的，通过C申请一个超过2GB内存的数组，然后交由Go去使用是常见的做法。

但需要注意的是，go程序应该在数组范围内去操作，以及需要调用c相关调用去释放。

## **c持有go分配的内存地址**

上面提到过，go运行时无论是gc还是栈伸缩，或者其他情况，都会改变内存的地址，因此长期运行的c程序（特别是非CPU计算型）如果持有go开辟的内存，而go运行时改变了的话，其结果就会出现 `segment fault`，程序崩溃。

解决方式也很简单：cgo调用时将go中对应的内存数据复制到c语言内存空间中，调用结束将c调用返回的内存数据复制到go内存空间中。

但这种解决方式在实际的生产代码中不可取的，因为大多用到cgo的场景可能都需要c/c++的高性能计算的优势，而频繁的内存拷贝则让这点优势荡然无存。

为了解决这个问题，**cgo保证在go程序传递数据给c调用开始到调用结束这段时间内，go程序不会改变这块内存**。看起来很完美，但很遗憾，软件工程没有银弹，go官方给出的这个方案也有缺陷**：假设c调用长时间运行，那么在c调用过程中引用的这块go内存不能被改变，从而间接的导致goroutine的栈不能伸缩，goroutine被阻塞、**

因此在c持有go内存的情况下，应避免长时间持有，或者做专门的优化。

## cgo实现的一些细节

了解cgo实现的同学都知道cgo会产生一些中间文件，为了进一步探究我的代码中cgo的布局，我手动生成了这部分文件。

```shell
go tool cgo -objdir=./cppkm/ km.go

```

生成了以下文件

```
_cgo.o
_cgo_export.c
_cgo_export.h
_cgo_flags
_cgo_gotypes.go
_co_main.c
km.cgo1.go
km.cgo2.c
```

其中和我们程序比较有关的是 `_cgo_gotypes.go`、`km_cgo1.go`、`km_cgo2.c`

`_cgo_gotypes.go`

```c++
// 省略一些不重要的代码

//go:cgo_import_static _cgo_743da1d4b169_Cfunc_entrance
//go:linkname __cgofn__cgo_743da1d4b169_Cfunc_entrance _cgo_743da1d4b169_Cfunc_entrance
var __cgofn__cgo_743da1d4b169_Cfunc_entrance byte
var _cgo_743da1d4b169_Cfunc_entrance = unsafe.Pointer(&__cgofn__cgo_743da1d4b169_Cfunc_entrance)

//go:cgo_unsafe_args
func _Cfunc_entrance(p0 *_Ctype_double, p1 _Ctype_long) (r1 *_Ctype_long) {
	_cgo_runtime_cgocall(_cgo_743da1d4b169_Cfunc_entrance, uintptr(unsafe.Pointer(&p0)))
	if _Cgo_always_false { 
		_Cgo_use(p0) 
		_Cgo_use(p1)
	}
	return
}

```

`_Cfunc_entrance`标记在变量`p0`和`p1`cgo中使用, 会导致p0和p1不会移动，而p0和p1就是调用`C.entrance` 的参数。

`_cgo_743da1d4b169_Cfunc_entrance` 则是cgo为我们生成代码的c函数。

```c
_cgo_743da1d4b169_Cfunc_entrance(void *v)
{
	struct {
		double* p0;
		long int p1;
		long int* r; // r是返回值
	} __attribute__((__packed__, __gcc_struct__)) *_cgo_a = v; // 这部分涉及到C ABI的内存布局
	char *_cgo_stktop = _cgo_topofstack();
	__typeof__(_cgo_a->r) _cgo_r;
	_cgo_tsan_acquire();
	_cgo_r = (__typeof__(_cgo_a->r)) entrance(_cgo_a->p0, _cgo_a->p1); // 真正调用了entrace
	_cgo_tsan_release();
	_cgo_a = (void*)((char*)_cgo_a + (_cgo_topofstack() - _cgo_stktop)); // 计算返回值地址 
	_cgo_a->r = _cgo_r;
	_cgo_msan_write(&_cgo_a->r, sizeof(_cgo_a->r)); // 写入go的内存空间mspan
}
```

`km.cgo1.go` 中的代码和我们自己的`km.go`代码整体差不多，唯一的区别在于

```go
result := ( /*line :109:12*/_Cfunc_entrance /*line :109:21*/)((* /*line :109:25*/_Ctype_double /*line :109:33*/)(unsafe.Pointer(&cArray[0])),  /*line :109:64*/_Ctype_long /*line :109:70*/(max_v_num)) //problem

```

对比一下我们的`km`.go

```go
result := C.entrance((*C.double)(unsafe.Pointer(&cArray[0])), C.long(max_v_num))
```

可以看到编译器帮我们插入了函数调用和返回值等代码。

接下来就可以想象到了，编译器会根据这些生成的代码进行编译。

# signal killed 原因排查

思考完CGO的内存模型后，其实对这个问题排查没有带来实质性的帮助，因为分析完内存模型后，发现cgo直接通过ABI调用并没有什么额外的内存开销，go和c各自使用自己的方式分配、使用和管理内存。

因此对于 `signal killed` 想到的是go调用c++代码时，由于内存不足，进而导致，c++内部初始化`km` 算法执行过程用到的变量失败。

于是希望寄托于能否找到在执行哪个调用的过程中收到了`signal kill` 信号，自然的想到通过 `strace` 去追踪，于是执行 `strace go test -v -run "TestDispatch10000_20" -timeout 100s ` ，程序收到 `singal killed` 之前最后一个系统调用是 `futex` ，这是一个内核级别的lock，因此还是没有实质性的帮助。

于是只能查看 kill的一些记录

` dmesg | egrep -i -B100 'killed process' `

得到了信息是

```
Out of mempry: Kill process 17443 (km.text) score 94 or sarifice child
kernel: killed process 17443 (km.test) total-vm:31354724kB, anon-rss:30636060kB, file-rss:476kB, shmem-rss:0kB
```

通过第一行信息，可以确定问题是`OOM`, Linux进程内存不足，进而决定杀掉score最高的进程。 决定score的因素除了内存占用大小之外，还有内存增长速率。 

第二行告诉了一些详细信息，简单解读一下：

- total-vm就是进程使用的虚拟内存大小，其中部分内容映射到RAM本身，也就是主存，被分配和使用也就成了RSS
- 部分RSS在实际内存块里面分配，成了anon-rss，叫做匿名内存。
- 还有映射到设备和文件的RSS内存卡，叫做file-rss。 

比如`malloc()`动态分配很大部分的内存，但没有使用它，那么total-vm会很高，但anon-rss会比较低，如果也用了它，那么anon-rss会很高。

在我的c++代码里使用了new去分配内存，对应的其实就是底层的`malloc`，并且计算过程中使用了它，因此看到的total-vm 和 anon-rss会很高。

# 解决方式

找到了问题的原因，解决方式也很简单，增大内存，但我是虚拟机，用了一种更简单的思路：增加swap大小。

具体做法如下：

```shell
dd if=/dev/zero of=/swapfile bs=1M count=2048 # dd命令写一个2GB字节的文件
mkswap /swapfile # mkswap 格式化为交互分区 
swapon /root/swapfile # swapon 启用交互分区
```

在运行测试用例时就不会出现 `signal killed` 问题，但速度会非常慢（使用了交换分区而不是内存）

# 总结

其实出现这个问题的条件非常苛刻，2GB大小虚拟机，并且运行了其他占用内存的进程，进而导致运行测试用例出现了这个问题。实际生成服务器往往是独立的撮合系统进程+大容量的内存，可能一辈子都不会出现这个问题。

但在测试阶段暴露问题也给自己提了一个醒：万一生成环境出现了这个问题呢？

