---
title: Docker的Alpine容器的时区问题
date: "2019-05-04"
categories: ["docker"]
tags: ["docker"]
---



# 适用对象
使用 Alpine Linux 发行版的 Docker 镜像容器。
仅仅适用于没有安装uclibc的系统。

# 修改步骤

1. 进入容器命令行

```shell
apk add -U tzdata

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

2. 验证时区

```shell
date
Tue Jan  9 22:53:46 CST 2018
```

3. 移除时区文件

```shell
apk del tzdata
```

为了保证容器的精简和轻量，移除下载的时区文件。