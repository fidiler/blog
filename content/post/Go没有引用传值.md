---
title: Go没有引用传值
date: "2017-03-08"
categories: ["go"]
tags: [go"]
---

Go没有引用变量，所以Go没有逐个引用函数调用语义。

# 什么是引用变量?

在像C/C++这样的语言中，可以声明别名或现有变量的替代名称。 这称为引用变量。

```c
#include <stdio.h>

int main() {
        int a = 10;
        int &b = a;
        int &c = b;

        printf("%p %p %p\n", &a, &b, &c); // 0x7ffe114f0b14 0x7ffe114f0b14 0x7ffe114f0b14
        return 0;
}
```

您可以看到a、b和c都指向相同的内存位置。写入a将改变b和c的内容。当您想在不同的范围内声明引用变量，即函数调用时，这是非常有用的。

# Go没有引用变量

与c++不同，Go程序中定义的每个变量都占据一个唯一的内存位置

```go
package main

import "fmt"

func main() {
        var a, b, c int
        fmt.Println(&a, &b, &c) // 0x1040a124 0x1040a128 0x1040a12c
}
```

不可能创建一个Go程序，其中两个变量在内存中共享相同的存储位置。

可以创建两个变量，它们的内容指向相同的存储位置，但这与两个共享相同存储位置的变量不同。

```go
package main

import "fmt"

func main() {
        var a int
        var b, c = &a, &a
        fmt.Println(b, c)   // 0x1040a124 0x1040a124
        fmt.Println(&b, &c) // 0x1040c108 0x1040c110
}
```

在这个例子中，b和c的值与a的地址相同，但是，b和c本身存储在惟一的位置。更新b的内容对c没有影响。

# 但是Map和channel都是引用

> 错了: 映射和通道不是引用。如果是，这个程序就会输出false。

```go
package main

import "fmt"

func fn(m map[int]int) {
        m = make(map[int]int)
}

func main() {
        var m map[int]int
        fn(m)
        fmt.Println(m == nil)
}
```

如果`map m`是一个c++风格的引用变量，那么main中声明的m和fn中声明的m将占用内存中相同的存储位置。但是，由于fn内部对m的赋值对m在main中的值没有影响，我们可以看出映射并不是引用变量。

# 如果一个map不是一个引用变量，它是什么?

在之前的文章中，我展示了Go `map`不是引用变量，也不是通过引用传递的。这就留下了一个问题，如果`map`不是引用变量，那么它们是什么?

对于没有耐心的人来说，答案是肯定的

> map值是指向`runtime.hmap`结构。

# map值的类型是什么?

当你写这个语法的时候

```go
m := make(map[int]int)
```

编译器用一个`runtime.makemap`的调用替换它

```go
// makemap implements a Go map creation make(map[k]v, hint)
// If the compiler has determined that the map or the first bucket
// can be created on the stack, h and/or bucket may be non-nil.
// If h != nil, the map can be created directly in h.
// If bucket != nil, bucket can be used as the first bucket.
func makemap(t *maptype, hint int64, h *hmap, bucket unsafe.Pointer) *hmap
```

如你所见，值的类型从`runtime.makemap`返回一个`runtime.hmap`的结构。我们无法从正常的Go代码中看到这一点，但我们可以确认`map`值与uintptr-one机器字的大小相同。

```go
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	var m map[int]int
	var p uintptr
	fmt.Println(unsafe.Sizeof(m), unsafe.Sizeof(p)) // 8 8 (linux/amd64)
}
```

# 如果map是指针，它们不应该是*map[key]value吗?

这是一个很好的问题，如果map是指针值，为什么表达式`make(map [int] int)`返回一个类型为`map[int] int`的值。 它不应该返回`*map [int]int`吗？

> 在早期，map是作为指针来写的，所以会写`*map[int]int`。但发现不写`*map`也能声明`map`时，就不在写`*map[int]int`这种语法了

#  结论

Go没有引用传递语义，因为Go没有引用变量。

`map`与`channel`类似，但和`slice`不同，`map`只是指向`runtime`的指针。如上所述，`map`只是指向`runtime.hmap`结构的指针。

`map`与Go程序中的任何其他指针值具有相同的指针语义。 除了编译器将`map`语法重写为对`runtime /hmap.go`中的函数的调用之外，没有什么神奇之处。