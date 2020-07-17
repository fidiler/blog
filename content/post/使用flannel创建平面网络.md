---
title: 使用flannel创建平面网络
date: "2019-04-02"
categories: ["docker"]
tags: ["docker","flannel"]
---



先看一下我们要解决的问题：位于**不同主机**的 Docker容器不通过端口而直接通信

## 准备环境

### 创建虚拟主机

这里我使用vagrant创建了3个虚拟机并安装好了docker, 3个主机的IP分别为

- 192.168.10.11
- 192.168.10.12
- 192.168.10.13

### 下载etcd和flannel

这里我们直接使用官方的releases版本

**etcd：**

https://github.com/coreos/etcd/releases

**flannel:**

https://github.com/coreos/flannel/releases

## 创建master

```shell
# 启动etcd
nohup ./etcd --listen-client-urls=http://0.0.0.0:2379 \
			--advertise-client-urls=http://192.168.10.11 &

# 将覆盖网络配置信息写入etcd
./etcdctl set /coreos.com/network/config '{"Network": "10.100.0.0/16"}'

# 启动flannel
./flanneld --iface=192.168.10.11 --ip-masq &

# 为docker0网络设备划分子网
mk-docker-opts.sh -c -d /etc/default/docker
```

## 配置woker节点

```shell
# 启动flannel
./flanneld --etcd-endpoints=http://192.168.10.12:2379 \
		  --iface=192.168.10.12 --ip-masq &
# 为docker0网络设备划分子网
./mk-docker-opts.sh -c -d /etc/default/docker
```

剩下主机重复上述操作

## 测试

在3台主机上启动一个容器，然后看是否能ping通