---
title: "GNU Make系列（一）Makefile入门"
date: "2017-06-12"
categories: ["软件开发"]
tags: ["make","makefile"]
---

# GNU Make

GNU Make工具由用户编写的程序脚本来控制构造的过程。

GNU Make提供了一整套编程语言，为makefile提供了足够的方式来描述构造股哟成。

GNU Make可以看成三种亚语言组成的：

- 文件依赖

  基于规则的语法，用来描述文件之间的依赖关系。执行的时候并非顺序执行，而是按照依赖执行。

- shell命令

  封装在每条规则中的shell命令，命令是按照顺序执行的

- 字符串处理

  通过操作GNU Make变量，使用函数过程编程范式，每个函数接受若干个字符串值作为输入， 并返回单个字符串值作为结果。

# Makefile规则

一个makefile中包含多个规则，每个规则描述如何根据若干输入文件，生成特定的标的文件。如果标的文件日志比相应的输入文件更旧，则执行shell命令序列，使之更新到最新状态。“更旧”是指标的文件时间戳比源文件小。

GNU Make不会像过程语言一样按顺序执行，而是采用另一套规则：根据标的文件名来确定与之匹配的规则。

```
calculator: add.o calc.o mult.o sub.o
	gcc -g -o calculator add .o calc.o mult.o sub,o
add.o: add.c numbers.h
	gcc -g -c add.c
calc.o: calc.c numbers.h
	gcc -g -c calc.c
mult.o: mult.c numbers.h
	gcc -g -c mult.c
sub.o: sub.c numbers.h
	gcc -g -c sub.c
```

## Makefile规则的类型

### 多个标的文件规则

规则的左边可以不止一个文件，例如：

```makefile
f1.o f2.o: s1.c s2.c s3.c
```

### 没有预备文件规则

如果想定义一个不依赖任何预备文件的标的文件，可以像下面这样

```makefile
.PHONY: help
help:
	@echo "Usage: make all ARCH=[i386|mips]"
	@echo "		  make clean"
```

当执行`make help`时，即使磁盘上不存在help文件，也会执行shell命令，同时也不会创建文件，因为不需要比对时间戳。

.PHONY指令表示GNU Make应当永远执行这个规则，即使把某个help文件放在当前目录中也必须执行

### 有文件名模式的规则

像下面这样：

```
add.o: add.c
	gcc -g -c add.c
```

每个标的文件都依赖与另一个文件。

为了简略可以使用通配符

```
%.o: %.c
```

它匹配任意两个满足以下条件的文件：标的文件以.o结尾，预备文件以.c结尾，且二者的开头字符序列完全相同。

### 只适用于某些文件的规则

为了让规则中的模式匹配更加有用，也可以声明其中的模式适用于哪些文件。例如：

```
a.o b.o: %.o: %.c
	echo This is rule is for a.o and b.o
c.o d.o: %.o: %.c
	echo This is rule is for c.o and d.o
```

### 有相同标的文件的多个规则：

虽然可以在一个规则行中定义标的文件所对应的多个预备文件，但如果把它们切分成多个规则，常常更有用。

```
chunk.o: chunk.c
	gcc -c chunk.c
chunk.o: chunk.h list.h data.h
```

上面的例子中，第一行规则声明chunk.o是由chunk.c生成的。而另一行规则chunk.o还依赖于多个其他c语言头文件。在这些规则中，只有一条规则包含shell命令，其他都只用来声明预备文件清单。

# Makefile变量

GNU Make的变量声明规则如下：

- 变量的值是通过赋值获得的，例如X:=5.

- 引用变量值的语法是$(x)

- 所有变量都是字符串型，其中可以容纳零个或多个字符。没有在变量使用之前声明变量机制，因此第一次向变量赋值时，也就创建了变量。

- 变量时全局类型，makefile中对变量X的所有赋值和引用都指向同一个变量

- 变量名可以包含大小写字母，数字和标点符号

  ```makefile
  1. FIRST := Hello there
  2. SECOND:= World 
  3. MESSAGE := $(FIRST) $(SECOND)
  4. FILES := add.c sub.c mult.c
  5. $(info $(MESSAGE) - The fukes are $(FILES))
  ```

  $(info …)指令，它将在输出设备上显示消息。

### 立即求值和延迟求值

使用`:=` 操作符，赋值语句的右边经过完全求值形成字符串常量，然后赋值给左边的变量。

使用`=`操作符，可以延迟变量的求值，不是立即将变量转换成常量字符串，而是直到实际使用变量时在进行求值

如：

```makefile
CC := gcc
CFLAGS := -g
CCOMP = $(CC) $(CFLAGS)
$(info Compiler is $(CCOMP))
CC := i386-linux-gcc
$(info Compilter is $(CCOMP))
```

第3行使用了延迟求值，当执行这个makefile时，不会立刻对第三行的变量进行求值，直到CCOMP被使用时才求值（4-6行），由于第5行修改了CC变量，因此CCOMP取值的时候也会被修改。

### 条件赋值

如果变量还没有值，则给变量赋值

```makefile
CFLAGS := -g
CFLAGS ?= -o
$(infio CFLAGS is $(CFLAGS))
```

# 内置变量和规则

- $@

  包含当前规则的标的文件名。有了$@,无须把标的文件名硬编码到shell命令中，而是可以使用\$@自动插入标的文件名。

- $<

  表示规则的第一个预备文件。如下列所示，使用$@来代表规则的标的文件名（生成的可执行文件）。而用\$<来代表源文件列表中的第一个文件

  ```makefile
  %.o: %.c
  	gcc -c -o $@ $<
  ```

- $^

  与$<类似，但它的求值结果时规则中所有预备文件的完整清单，各文件之间空格符隔开。

- $(@D)

  对标的文件所在目录进行求值。例如，如果标的文件时/home/xyc/workspace/src.c 则$(@D) 的结果是

  /home/xyc/workspace。当使用mkdir等shell命令时，这个自动变量很有用

- $(@F)

  与$(@D)类似，但它的求值结果是标的文件的本名。如果标的文件时/home/xyc/workspace/src.c \$(@F)的结果就是src.c

  更多内置变量规则参考

  http://www.gnu.org/software/make/manual/make.html#toc-How-to-Use-Variables

除了自动变量外，还内置了一些规则

c语言内置规则：

- CC
- CFLAGS
- CPPFLAGS
- TARGET_ARCH

在使用这些变量时，可以进行延迟求值。

比如：

```makefile
SRCS = add.c calc.c mult.c sub.c 
PROG = calculator
cc = gcc
CFLAGS = -g
OBJS = $(SRCS:.c=.o)
$(PROG): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^
  
$(OBJS): numbers.h
```

# 数据结构与函数

有如下数据结构：

```makefile
PROG_NAME := calculator
LIST_OF_SRCS := calc.c main.c math.h lib.c
COLORS := red FF0000 green 00FF00 blue 0000FF purple FF00FF
ORDERS := 100 green cups 200 blue plates
```

下面来看一些常用的字符串处理函数：

- words

  对于给定的输入列表，返回列表中的单词（空格区分）的个数

  ```makefile
  NUM_FILES := $(words $(LIST_OF_SRCS))
  // $(NUM_FILES) = 4
  ```

- word

  对于给定的输入列表，从中获得第n各单词。

  ```makefile
  SECOND_FILE := $(word 2, $(LIST_OF_SRCS))
  // $(SECOND_FILE) main.c
  ```

- filter

  返回列表中与特定模式相匹配的单词。本函数常用于筛选出与特性文件名模式匹配的文件子集

  ```makefile
  C_SRCS := $(filter %.c, $(LIST_OF_SRCS))
  ```

- patsubst

  对于列表中的每个单词，将于特定模式相匹配的单词替换成指定的替换模式%字符表示单词中保持不变的部分。第一个都好后面不能跟空格

  ```makefile
  OBJSRCS := $(patsubst %.c,%.o, $(C_SRCS))
  ```

  与$(C_SRCS:.c=.o)类似

- addprefix

  为列表中的每个单词附加一个前缀字符串。　

  ```makefile`
  OBJ_LIST := $(addprefix objs/, $(OBJESTS))
  // $(OBJ_LIST) objs/calc.o objs/math.o objs/lib.o
  ```

- foreach

  读取列表中每个单词，并生成新列表，其中包含 “映射值”。可以由任何内置函数组成。

  ```
  OBJ_LIST_2 := $(foreach file, $(OBJECTS), objs/$(file))
  ```

  与addprefix相同，其中声称了新的列表，列表中所由文件名都应映射为 objs/(file)表达式。

- dir/notdir

  对于给定的文件路径名，返回其中的目录名或文件名部分

  ```makefile
  DEFN_PATH := src/headers/idl/interface.idl
  DEFN_DIR := $(dir $(DEFN_PATH))
  DEFN_BASENAME := $(notdir $(DEFN_PATH))
  # $(DEFN_DIR) src/headers/idl/ 包含最后的/
  # $(DEFN_BASENAME) interface.idl
  ```

- shell

  执行shell命令，并以字符串的形式返回命令输出的结果

  ```makefile
  PASSWORD_OWNER := $(word 3, $(shell ls -l /etc/password))
  ```

- 宏

  宏可以为更复杂的构建表达式命名，并将向表达式传递参数。这样就可以编写自己的GNU Make函数。

  ```makefile
  file_size = $(word 5, $(shell ls -l $(1)))
  PASSWORD_SIZE := $(call file_size, /etc/password)
  ```

  定义了一个file_size宏，其返回的结果是文件的字节数，$(1)是用来指代语法\$(call)表达式的第一个参数

  另一种快捷的方式是使用define指令来定义一个shell命令的封装。

  ```makefile
  define start-banner
  	@echo ===============
  	@echo Starting build
  	@echo ===============
  endef
  
  .PHONY all
  all:
  	$(start-banner)
  	$(MAKE) -C lib1
  ```

  更多函数参考：

  http://www.gnu.org/software/make/manual/make.html#toc-Functions-for-Transforming-Text

# GNU Make程序流程

1. 解析makefile

   解析makefile涉及两个阶段，第一阶段是读取makefile，建立依赖关系图，第二阶段是执行编译命令。

   makefile实质上是对依赖关系的文本格式的表达，而依赖关系本身又是一种体现文件之间关系的数学结构。

2. 控制解析过程

   GNU Make提供了许多特性，用来控制如何引入makefile子文件，如何对makefile的部分内容进行有条件的编译

3. 执行规则

   规执行的算法确定了规则处理的顺序，并执行相应的shell命令

## 解析makefile

- makefile解析

  系统对makefile进行解析和验证，生成完整的依赖关系图。系统扫描所有规则，对全部变量进行赋值，并对所有变量进行验证和解析，如果生成关系图出现错误，都会在这个阶段报告。

- 规则执行

  当整个依赖关系图解析完毕并载入到内存中，GNU Make就检查所有文件的时间戳来确定是否有文件过期。如果发现过期文件，则执行适当的shell命令

  ```makefile
  X := hello world
  print:
  	echo X is $(X)
  
  X := Goodbyte
  ```

  执行结果是 X is Goodbyte 不难发现，shell命令都是在第二阶段执行的

## 控制解析过程

GNU Make流程控制影响着程序的执行。

- 文件包含

  可以引入另外的问题，如同它们是makefile主文件的组成部分。

  ```makefile
  FILES := s1.c s2.c
  include prog.mk
  				#prog.mk中的内容将插入在这里和当前makefile构成一个主文件
  
  s1.o s2.o: s.h
  ```

- 条件编译

  可以通过指定条件涵盖或消除makefile部分内容。这种涵盖是在makefile解析的第一阶段执行的，因此条件表达式必须相当简单才行（而不是使用shell命令）

  ```makefile
  CFLAGS := -DPATH="/usr/local"
  ifdef DEBUG
  	CFLAGS += -G
  else
  	CFLAGS += -O
  endif
  ```

## 执行规则

1. 使用shell调用make命令时，必须指定要构造的标的文件，标的文件一般是可执行程序，当然也可以是all或install之类与实际磁盘文件无关的伪标的文件。

   如：make all

   如果没有指定标的文件，则会尝试构造makefile列出的第一个标的文件

   如：make , 假如第一个标的文件是 all ，那么就等同于make all

2. 如果GNU Make找到一条用来生成标的文件的规则。则检查这条规则中列出的每个预备文件，并将它们迭代作为标的文件。这就确保了用作编译工具输入的文件每个文件本身是新状态。

   如：把add.o和cal.o文件链接形成可执行程序calculator之前，GNU Make迭代搜索左边是add.o和calc.o的规则

3. 如果找到满足标的文件的规则

   1. 如果规则对应标的文件还不存在，则执行该桂娥的shell命令序列，首次创建该文件。这种情况通常放生在编译一个全新的源树、还未创建任何目标文件时。
   2. 如果磁盘上已有标的文件，则对每个预备文件的时间戳进行检查，看看有无更新，如果有的话，则重新生成标的文件

4. 如果第三步失败，表示makefile中没有合适的规则来生成标的文件，那么存在以下选择：

   1. 如果磁盘上有标的文件，则停止
   2. 如果磁盘上没有标的文件，报错停止