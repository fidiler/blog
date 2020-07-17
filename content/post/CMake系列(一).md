---
title: "CMake系列（一）如何使用CMake 构建Hello world"
date: "2017-08-19"
categories: ["软件开发"]
tags: ["CMake"]
---



# CMake构建Hello world

本节演示使用CMake编译hello world

CMakeLists.txt 中定义了编译过程中需要的一些信息

## 开始构建

首先创建 build 目录 ` mkdir build && cd build`

然后进行编译 `cmake ..`

之后你会发现系统自动生成了: CMakeFiles, CMakeCache.txt, cmake_install.cmake等文件，并且生成了 Makefile.
现在不需要理会这些文件的作用，以后你也可以不去理会。最关键的是，它自动生成了Makefile.

接着我们使用 `make` 命令

这时候，我们需要的目标文件 hello 已经构建完成，位于当前目录，尝试运行一下: ./hello

## 指令介绍

针对CMakeLists.txt 这个文件定义的信息进行解释，

### PROJECT

PROJECT 指令的语法是:

`PROJECT(projectname [CXX] [C] [Java])`

这个指令用于定义工程名称，并可指定工程的语言。该指令会隐式定义了两个变量

`projectname_BINARY_DIR` 和 `projectname_SOURCE_DIR`

这两个变量等同于 `PROJECT_BINARY_DIR` 和 `PROJECT_SOURCE_DIR`

### SET

SET 指令的语法是:

SET(VAR [VALUE] [CACHE TYPE DOCSTRING [FORCE]])

现阶段，你只需要了解 SET 指令可以用来显式的定义变量即可。 比如我们用到的是SET(SRC_LIST main.c)，
如果有多个源文件，也可以定义成: SET(SRC_LIST main.c t1.c t2.c)。

### MESSAGE

MESSAGE 指令的语法是:

MESSAGE([SEND_ERROR | STATUS | FATAL_ERROR] "message to display"...)

这个指令用于向终端输出用户定义的信息，包含了三种类型:
- SEND_ERROR，产生错误，生成过程被跳过。
- STATUS，输出前缀为—的信息。
- FATAL_ERROR，立即终止所有 cmake 过程.

### ADD_EXECUTABLE

ADD_EXECUTABLE(hello ${SRC_LIST})

定义了这个工程会生成一个文件名为 hello 的可执行文件

## 基本语法规则

最简单的两条语法规则：

- 变量使用${}方式取值，但是在 IF 控制语句中是直接使用变量名
- 指令(参数1 参数2...)

## 小结

我们介绍了以下几个指令：
- project
- message
- set
- add_executable

同时介绍了两个隐含的变量：
- projectname_BINARY_DIR
- porjectname_SOURCE_DIR

两个全局变量:
- PROJECT_BINARY_DIR
- PROJECT_SOURCE_DIR