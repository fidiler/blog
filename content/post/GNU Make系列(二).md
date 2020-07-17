---
title: "GNU Make系列（一）Makefile实例"
date: "2017-06-21"
categories: ["软件开发"]
tags: ["make","makefile"]
---



# 场景1: 源代码放在单个目录中

```makefile
SRCS := add.c calc.c mult.c sub.c
PROG = calculator
CC = gcc
CFLAGS = -g
OBJS = $(SRCS:.c=.o)

$(PROG): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

include $(SRCS:.c=.d)

%.d: %.c
	@$(CC) -MM $(CPPFLAGS) $< | sed 's#\(.*\)\.o: #\1.o\1\1.d: #g' > $@
```

这个makefile会针对每个c源文件，生成对应心的依赖信息文件.d。在这个例子中，会生成add.d、calc.d、mult.d和sub.d四个文件。这些依赖关系文件的内容如下（add.d为例）：

add.o add.d: add.c numbers.h

makefile显示的包含了所有.d文件。通过向gcc传递 -MM参数，它要求编译器生成所读入的.c或.h文件清单，但在生成清单后立即停止工作，不执行真正的编译工作。最后sed命令把.d文件的文件名加到规则的左边。

# 场景2

## 源代码放在多个目录中

假如有以下一个程序

```makefile
src
	Makefile
	calc
		calc.c
	libmath
		clock.c
		letter.c
		libmath.a
		number.c
	libprint
		banner.c
		center.c
		normal.c
```

我们可以使用但目录的方式来处理多目录

```makefile
SRCS = libmath/clock.c libmath/letter.c libmath/number.c\
	   libprint/banner.c libprint/center.c libprint/normal.c \
	   	cal/calc.c
...
```

但这个方式存在以下问题

- 依赖关系更难以生成
- 多个人使用但个makefile的冲突问题
- 无法对程序进行分解

## 对多个目录进行迭代式Make操作

基本方法是在每个源目录下放一个不同的makefile，并用一个更高层次的makefile（上级目录）迭代调用每个下级目录的makefile

因为较之但文件的方式改造为

```makefile
src
	Makefile
	calc
		Makefile
		calc.c
	libmath
		Makefile
		clock.c
		letter.c
		libmath.a
		number.c
	libprint
		Makefile
		banner.c
		center.c
		normal.c
```

libmath/Makefile:

```makefile
SRCS = clock.c letter.c number.c
LIB =libmath.a
CC = gcc
CFLAGS = -g
OBJS = $(SRCS:.c=.o)

$(LIB): $(OBJS)
	$(AR) cr $(LIB) $(OBJS)

$(OBJS): math.h
```

上面的makefile .c文件显示声明的，通过AR链接成静态库

libprint/Makefile

```makefile
SRCS = banner.c center.c normal.c
LIB = libprint.a
include lib.mk
$(OBJS): printers.h

```

lib.mk

```makefile
CC = gcc
CFLAGS = -g
$(LIB): $(OBJS)
	$(AR) cr $(LIB) $(OBJS)
```

calc/Makefile

```makefile
SRCS = calc.c
PROG = calculator
LIBS = ../libmath/libmath.a ../libprint/libprint.a
CC = gcc
CFLAGS.= -g
$(PROG): $(OBJS) $(LIBS)
	$(CC) -o $@ $^
```

Makefile

```mnkefile
.PHONY: all
all:
	$(MAKE) -C libmath
	$(MAKE) -C libprint
	$(MAKE) -C calc
```

## 对多个目录进行包含式Make操作

```
src
	Files.mk
	Makefile
	application
		Files.mk
		database
			Files.mk
            load
                Files.mk
            save
                Files.mk
        graphics
            Files.mk
    libraries
    	Files.mk
    	math
    		Files.mk
    	protocols
    		Files.mk
    	sql
    		Files.mk
    	weidets
    		Files.mk
    make
    	framework.mk
```

- src/Files.mk

  ```makefile
  SUBDIRS := libraries application
  SRC := main.c
  CFLAGS := -g
  ```

- src/libraries/Files.mk

  ```makefile
  SUBDIRS := math protocols sql weidets
  ```

- src/libraries/math/Files.mk

  ```makefile
  SRC := add.c mult.c sub.c
  CFLAGS := -DBIG_MATH
  ```

SUBDIRS列出来构造过程要包含的目录

其次，每个Files.mk中的SRC变量告诉构造系统，应当把该目录中的哪些文件包含进来

最后，CFLAGS变量声明了对于本目录中所有源文件，应当使用c编译器的哪个参数

- src/Makefile

  ```makefile
  _subdirs := 
  _curdir := 
  FRAMEWORK := $(CURDIR)/make/framework.mk
  include Files.mk
  include $(FRAMEWORK)
  
  VARS := $(sort $(filter src-% cflags-%, $(.VARIABLES)))
  $(foreach var, $(VARS), $(info $(var) = $($(var))))
  ```

  第1行，_subdirs变量初始化为空字符串。该变量内容为以空格却分的待遍历目录列表。在每个字目录中，都可以找到Files.mk文件。其中可能包含SUBDIRS变量，每当找到一个SUBDIRS定义，就把心的字目录追加到_subdirs现有内容末尾。

  例如在访问了src/Files.mk后，_subdirs包含如下内容：

  libraries applications

  下一步是从队列开头取出libraries路径，从而解析src/libraries/Files.mk文件。当在其中发现了SUBDIRS定义后，_subdirs就变成了：

  applications libraries/math libraries/protocols libraries/sql libraries/widegts

  重复这一过程，最后遍历了整个构造树。也读取了每个Files.mk文件。

  第2行，_curdir变量初始化为空字符串，这个变量代表正在遍历的当前目录。在开始时它是空的，因为当前位于构造树的顶端，随着构造树的遍历，不断从_subdirs队列头部取出目录名，_curdir反映了当前正在遍历的位置。

  第3行，把FRAMEWORK定义为这个框架makefile的路径。

  第4行，把src/Files.mk引入，启动整个进程。可以获得SRC 、SUBDIRS、CFLAGS变量的最顶层定义。这里需要注意的是，include指令包含其他文件，和使用$(make)调用make file是有区别的。include此时系统仍然使用的是同一个make进程。从而每次都是向同一个依赖关系图增加新内容

  第5行，调用包含式make框架，来处理SRC、SUBDIRS 和CFLGAS变量的内容，该框架随继续遍历源树的剩余目录。当从这个指令返回时，系统已经把所有Files.mk都处理了。

  第7行和第8行，执行于Files.mk片断的整个树都被处理完成后。这些代码对GNU Make所知的全套变量列表（自动保存在$(.VARIABLES)中）进行处理，将其中变量名以srcs-或flags-开头的变量全部过滤出来。

  然后这些过滤出来的变量逐个显示在程序的输出信息中，方便查看结果。

  这些srcs-*和flags-\* 是在框架遍历构造树的过程中定义的。

- make/framework.mk

  ```makefile
  srcs-$(_curdir) := $(addprefix $(_curdir), $(SRC))
  cflags-$(_curdir) := $(CFLAGS)
  _subdirs := $(_subdirs) $(addprefix $(_curdir), $(SUBDIRS))
  
  ifneq ($(words $(_subdirs)), 0)
  	_curdir := $(firstword $(subdirs)) /
  	_subdirs := $(wordlist 2, $(words $(subdirs)),$(_subdirs))
  	SUBDIRS := 
  	SRC := 
  	CFLAGS :=
  	include $(_curdir)Fles.mk
  	include $(FRAMEWORK)
  endif
  ```

  第1行，记录了当前目录的源文件集合。赋值等到左边也包含了一个变量，因此它是为所访问的每个目录分别创建一个不同的变量。

  crcs-libraries/math := libraries/math/add.c libraries/math/mult.c libraries/math/sub.c

  第3行，对当前Files.mk片断可能包含的其他SUBDIRS变量值进行排队处理。并把这些值追加到$(_subdirs)现有值的末尾

  第5～13行，对源代码目录树进行遍历。假定在待遍历字目录有多个条目，就首先取出一条，并取出目录中的Files.mk

  第6行，把_subdirs列表中的第一个元素设置为当前目录 (即_curdir的值)

  第7行，从队列中删除这第一个元素，方法是对_subdirs重新赋值，赋值内容是从第二个条目开始到_subdirs的末尾

  第11行，包含当前目录中Files.mk片断的内容，假定Files.mk并未包含定义(SRC SUBDIRS CFLAGS)，那么首先将它们设为空字符串。

  第12行，重复循环整个框架文件。存储 SRC和CFLGAS的值，然后遍历SUBDIRS列出的其他目录

# 场景3：定义新的编译工具

可能编译的不只是c语言的源文件,需要加入新的编译工具

```makefile
MATHCOMP := /tools/bin/mathcomp
CC := gcc
MATHSRC := equations.math
CSRC := calculator.c
PROG := calculator
OBJS := $(CSRC:.c=.o) $(MATHSRC:.math=.o)

$(PROG): $(OBJS)
	$(cc) -o $@ $^

%.c: %.math
	$(MATHCOMP) -c $<

-include $(CSRC:.c=.d)
-include $(MATHSRC:.math=.d)

%.d:%.c
	@(CC) -MM $(CPPFLAGS) $< | sed 's@\(.*)\.o: #\1.o'
	
%.d1: %.math
	echo -n "$@ $(*F).c: " > $@;\
	$(MATHCOMP) -d $< >> $@
```

# 场景4: 针对多个变量进行构造

比如根据不同的平台架构编译出不同的可执行文件，给定PLATFORM变量的值，如果没有这个值默认使用x86平台的架构

```shell
make PLATFORM=powerpc

make # default x86

Make PLATFORM=xbox

# invalid PLATFORM: xbox
```

```makefile
SRCS = add.c calc.c mult.c sub.c
PROG = calci;ator
CFLAGS = -g
PLATFORM ?=i386
VALID_PLATFORMS i386 powerpc alpha
ifneq ($(filter $(PLATFORM), $(VALID_PLATFORMS)), )
	$(error Invalid PLATFORM: $(PLATFORM))
endif

OBJDIR=obj/$(PLATFORM)
$(shell mkdir -p $(OBJDIR))
CC := gcc-$(PLATFORM)
OBJS = $(addprefix $(OBJDIR)/, $(SRCS:.c=.o))
$(OBJDIR)/$(PROG): $(OBJS)
	$(cc) $(CFLAGS) -o $@ $^

$(OBJDIR)/%.o: %.c
	$(CC) -c -o $@ $<
$(OBJS): numbers.h
```



# 场景5: 清除构造树

```makefile
.PHONY: clean
clean:
	$(MAKE) -C libmath clean
	$(MAKE) -C linprint clean
	$(MAKE) -c calc clean
```

对于每个子目录

```makefile
.PHONY: clean
clean:
	rm -rf $(OBS) $(LIB)
```