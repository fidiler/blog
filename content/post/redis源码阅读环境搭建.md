---
title: "Redis 源码阅读环境"
date: "2017-04-18"
categories: ["Redis"]
tags: ["Redis"]
---

我从 github 上 fork 了一份有CMake支持的repo自己维护, 该repo链接为: https://github.com/chendotjs/redis-v3.0.0

我维护的repo链接为: https://github.com/Soul-Mate/redis-v.3.0.0-src

## 一些工具

编辑器我使用了两个，分别是

- [Spacevim](https://spacevim.org/) 
- [Clion](https://www.jetbrains.com/clion/)

调试工具使用 gdb

## 编译源码

开始编译前需要安装以下依赖

- cmake
- gcc

```shell
git@github.com:Soul-Mate/redis-v.3.0.0-src.git

cd redis-v.3.0.0-src && mkdir build && cd build

cmake -DCMAKE_BUILD_TYPE=Debug ..

cp ../redis.conf ./ && ./redis-server redis.conf # 验证是否编译成功
```

接下来我们就可以使用自己擅长的debug方式去阅读源码了.