---
title: "探索DNS"
date: "2018-03-01"
categories: ["计算机网络"]
tags: ["ip","dns"]
---

我们知道在数据链路层不使用IP地址,而是使用mac地址, 两个主机通信必须知道对方mac地址, IP地址则根据一定的规则转换为mac地址.

同样的,在访问Web站点和发送、接收电子邮件时，我们通常会直接输入Web网站的地址或电子邮件地址等那些由应用层提供的地址，而不会使用由十进制数字组成的某个IP地址.

不使用IP地址的原因是IP地址**不方便记忆**.

我们平常在访问某个网站时不使用IP地址，而是用一串由罗马字和点号组成的字符串。
能够这样做是因为有了DNS（Domain Name System）功能的支持。DNS可以将那串字符串自动转换为具体的IP地址。

# DNS背景

TCP/IP有一个叫做主机识别码的东西。这种识别方式是指为每台计算机赋以唯一的主机名，在进行网络通信时可以直接使用主机名称，系统自动将主机名转换为具体的IP地址。为了实现这样的功能，主机往往会利用一个叫做hosts的数据库文件。

![hosts文件](https://upload-images.jianshu.io/upload_images/14252596-98f442c3419d4b7d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

起初由互联网信息中心（SRI-NIC）整体管理一份hosts文件。然而，随着网络规模的不断扩大、接入计算机的个数不断增加，使得这种集中管理主机名和IP地址的登录、变更处理的可行性逐渐降低。

在上述背景之下，产生了一个可以有效管理主机名和IP地址之间对应关系的系统，那就是DNS系统。

在实际应用中，DNS会根据用户输入的域名自动检索IP地址

>  nslookup 命令会返回对应的IP地址

# 域名构成

在理解DNS前需要先理解域名。

域名由几个英文字母（或英文字符序列）用点号连接构成。例如 `http://www.jianshu.com`

DNS 域名是分成构成的，结构像是一颗倒着的树。

![分层的域名](https://upload-images.jianshu.io/upload_images/14252596-b0cf9fd7ebab21e4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

根域名称为 `root` 也叫顶点，顶点的下一层叫做顶级域名（TLD：Top Level Domain） 。
它包括“jp（日本）”、“uk（英国）”等代表国家的国别顶级域名（ccTLD：country code TLD） 。
还包括代表 edu（美国教育机构）或 com（美国企业）等特定领域的通用顶级域名（gTLD：generic TLD）。

## 域名服务器

每层都设有一个域名服务器，域名服务器是指管理域名的主机和相应的软件，它可以管理所在分层的域的相关信息。其所管理的分层叫做 zone。

![域名服务器](https://upload-images.jianshu.io/upload_images/14252596-695acd273184ebef.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 根域名服务器

根部所设置的DNS服务器叫做根域名服务器，根域名服务器中注册着根以下第1层域名服务器的IP地址。
根域名服务器对DNS的检索数据功能起着至关重要的作用。
根据DNS协议，根域名服务器可由**13个IP地址**表示，并且从A到M开始命名。（然而，现在由于IP任播可以为多个节点设置同一个IP地址，为了提高容灾能力和负载均衡能力，根域名服务器的个数也在不断增加）。

## 域名解析器
进行DNS查询的主机和软件叫做DNS解析器，用户所使用的工作站或个人电脑都属于解析器。
一个解析器至少要注册一个以上域名服务器的IP地址。通常至少包括组织内部的域名服务器的IP地址。

# DNS解析和查询
解析器为了查找IP地址，会像域名服务器进行查询处理，域名服务器收到查询请求会在自己的数据库中查找。如果有该域名所对应的IP地址就返回。如果没有，则域名服务器再向上一层根域名服务器进行查询处理。
因此，从根开始对这棵树按照顺序进行遍历，直到找到指定的域名服务器，并由这个域名服务器返回想要的数据。

![DNS查询](https://upload-images.jianshu.io/upload_images/14252596-cb75d676d70df7f8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


# DNS如同互联网中的分布式数据库
DNS是一种通过主机名检索IP地址的系统。然而，它所管理的信息不仅仅是这些主机名跟IP地址之间的映射关系。它还要管理众多其他信息。

例如，主机名与IP地址的对应信息叫做A记录。反之，从IP地址检索主机名称的信息叫做PTR。此外，上层或下层域名服务器IP地址的映射叫做NS记录。

![DNS记录](https://upload-images.jianshu.io/upload_images/14252596-9a07a3f0c68caf7a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



当我们输入一个域名时我们知道DNS会将域名解析成相应的IP地址，那么解析过程是什么样的呢？下面将通过一些工具来追踪DNS的解析过程，不过在此之前我们先理一下大致的解析流程。

# DNS解析流程

假如我要查询 `www.baidu.com` 这个域名的IP，DNS解析大致分为如下步骤：
1. 首先像 ISPDNS （也可能是自动配置的DNS地址或手动配置的地址，例如：8.8.8.8）发起一个DNS查询请求
2. ISPDNS拿到请求后，先检查一下自己的缓存中有没有这个地址，有的话就直接返回。这个时候拿到的ip地址，**会被标记为非权威服务器的应答**。
3. 如果缓存中没有的话，ISPDNS会从配置文件里面读取13个根域名服务器的地址，然后像其中一台发起请求
4. 服务器拿到这个请求后，知道他是com.这个顶级域名下的，所以就会返回com域中的NS记录（一般来说是13台主机名和IP）
5. 然后ISPDNS向其中一台再次发起请求，com域的服务器发现你这请求是baidu.com这个域的，同样会返回baidu.com域中的NS记录
6. ISPDNS再次向baidu.com这个域的权威服务器发起请求，baidu.com收到之后，查有没有www的这台主机，如果有就把这个IP返回
7. ISPDNS拿到了之后，将其返回客户端，并且把这个保存在高速缓存中

我们用图来将这个流程更加形象化
![](https://upload-images.jianshu.io/upload_images/14252596-93cbf06b0833c556.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 追踪DNS解析（www.google.com）
下面我们将追踪 `www.google.com` 这个域名（我本机配置的DNS为8.8.8.8）

首先使用 `nslookup www.google.com` 发起查询，查询得到如下结果

```
Server:		8.8.8.8  
Address:	8.8.8.8#53

Non-authoritative answer:
Name:	www.google.com    # 
Address: 216.58.200.36
Name:	www.google.com
Address: 2404:6800:4008:801::2004

// Server: DNS服务器的主机名
// Address: DNS服务器的IP地址

// Name: 需要查询的URL
// Address: 解析出的IP地址 
```

接着我们使用 `wireshark` 来追踪DNS网络包
![wireshark数据包](https://upload-images.jianshu.io/upload_images/14252596-88d704c3cbd7f784.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从图中可以看到我本机向 `8.8.8.8` 发起了一个DNS查询数据包。

![查询数据包](https://upload-images.jianshu.io/upload_images/14252596-3158386ffbf25d6d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

查询数据包中 Query 字段包含了需要查询的地址（具体可以自行了解DNS协议格式）

`8.8.8.8` 这个DNS服务器收到查询数据包后响应了一个数据包给我本机，从而获得了 IP 地址
![响应数据包](https://upload-images.jianshu.io/upload_images/14252596-ddfd9e46b50bc779.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

响应数据包中 Answers 字段返回了域名的IP地址

第二次发起查询和第一次查询过程一样，区别是查询的 **IPv6**

## 追踪DNS解析（www.baidu.com）
追踪完 `www.google.com` 这个域名后我们来追踪一个更加复杂的域名 `www.baidu.com`，该域名复杂在哪里呢？
我们还是先使用 `nslookup www.baidu.com` 来查询
```
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
www.baidu.com	canonical name = www.a.shifen.com.
www.a.shifen.com	canonical name = www.wshifen.com.
Name:	www.wshifen.com
Address: 103.235.46.39
```
那么有没有发现和  `nslookup www.google.com` 不一样呢？
仔细观察你会发现多了一个 `www.baidu.com   canonical name = www.a.shifen.com.` 和 `www.a.shifen.com    canonical name = www.wshifen.com.`

为什么会出现这个? 我们使用 `wireshark` 来分析一下DNS协议
![wireshark数据包](https://upload-images.jianshu.io/upload_images/14252596-06552cae7d02ff30.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

好像并没有与之前有什么区别，我们先查看 DNS查询数据包中的详情
![DNS查询包](https://upload-images.jianshu.io/upload_images/14252596-e277a0e824ecbff8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

可以看到数据包和之前的内容大体一致。

接着看响应数据包
![DNS响应包](https://upload-images.jianshu.io/upload_images/14252596-8fc158dc0b55a231.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
仔细观察会发现 `www.baidu.com` 最终指向了  `CNAME = www.a.shifen.com`  

这是什么意思呢？我们继续分析

使用 `dig +trace www.baidu.com` 追踪DNS详细的执行流程

首先选择一个 root-server 查询`.com` 域名
```
; <<>> DiG 9.11.3-1-Debian <<>> +trace www.baidu.com
;; global options: +cmd
.			133465	IN	NS	m.root-servers.net.
.			133465	IN	NS	b.root-servers.net.
.			133465	IN	NS	c.root-servers.net.
.			133465	IN	NS	d.root-servers.net.
.			133465	IN	NS	e.root-servers.net.
.			133465	IN	NS	f.root-servers.net.
.			133465	IN	NS	g.root-servers.net.
.			133465	IN	NS	h.root-servers.net.
.			133465	IN	NS	i.root-servers.net.
.			133465	IN	NS	j.root-servers.net.
.			133465	IN	NS	a.root-servers.net.
.			133465	IN	NS	k.root-servers.net.
.			133465	IN	NS	l.root-servers.net.
```

接着从 root-server 接收到 `.com` NS的记录
```
com.			172800	IN	NS	l.gtld-servers.net.
com.			172800	IN	NS	b.gtld-servers.net.
com.			172800	IN	NS	c.gtld-servers.net.
com.			172800	IN	NS	d.gtld-servers.net.
com.			172800	IN	NS	e.gtld-servers.net.
com.			172800	IN	NS	f.gtld-servers.net.
com.			172800	IN	NS	g.gtld-servers.net.
com.			172800	IN	NS	a.gtld-servers.net.
com.			172800	IN	NS	h.gtld-servers.net.
com.			172800	IN	NS	i.gtld-servers.net.
com.			172800	IN	NS	j.gtld-servers.net.
com.			172800	IN	NS	k.gtld-servers.net.
com.			172800	IN	NS	m.gtld-servers.net.
;; Received 525 bytes from 8.8.8.8#53(8.8.8.8) in 55 ms
```
继续选择一台查询 `baidu.com` 并从 `.com` 接收到 `baidu.com` NS的记录
```
baidu.com.		172800	IN	NS	ns2.baidu.com.
baidu.com.		172800	IN	NS	ns3.baidu.com.
baidu.com.		172800	IN	NS	ns4.baidu.com.
baidu.com.		172800	IN	NS	ns1.baidu.com.
baidu.com.		172800	IN	NS	ns7.baidu.com.
;; Received 1173 bytes from 192.203.230.10#53(e.root-servers.net) in 45 ms
```

继续选择一台 查询 `www.baidu.com` 
```
www.baidu.com.		1200	IN	CNAME	www.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns3.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns5.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns1.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns4.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns2.a.shifen.com.
;; Received 239 bytes from 112.80.248.64#53(ns3.baidu.com) in 9 ms
```
按照一般的逻辑，当DNS请求到别名的时候，查询会终止。并重新发起查询别名的请求，所以此处应该返回的是`www.a.shifen.com`
但是这里返回a.shifen.com的这个域的NS

继续使用 `dig +trace www.a.shifen.com` 追踪 `www.a.shifen.com.` 
```
; <<>> DiG 9.11.3-1-Debian <<>> +trace www.a.shifen.com
;; global options: +cmd
.			131120	IN	NS	m.root-servers.net.
.			131120	IN	NS	b.root-servers.net.
.			131120	IN	NS	c.root-servers.net.
.			131120	IN	NS	d.root-servers.net.
.			131120	IN	NS	e.root-servers.net.
.			131120	IN	NS	f.root-servers.net.
.			131120	IN	NS	g.root-servers.net.
.			131120	IN	NS	h.root-servers.net.
.			131120	IN	NS	i.root-servers.net.
.			131120	IN	NS	j.root-servers.net.
.			131120	IN	NS	a.root-servers.net.
.			131120	IN	NS	k.root-servers.net.
.			131120	IN	NS	l.root-servers.net.
.			131120	IN	RRSIG	NS 8 0 518400 20190312170000 20190227160000 16749 . 
;; Received 525 bytes from 8.8.8.8#53(8.8.8.8) in 57 ms

com.			172800	IN	NS	l.gtld-servers.net.
com.			172800	IN	NS	b.gtld-servers.net.
com.			172800	IN	NS	c.gtld-servers.net.
com.			172800	IN	NS	d.gtld-servers.net.
com.			172800	IN	NS	e.gtld-servers.net.
com.			172800	IN	NS	f.gtld-servers.net.
com.			172800	IN	NS	g.gtld-servers.net.
com.			172800	IN	NS	a.gtld-servers.net.
com.			172800	IN	NS	h.gtld-servers.net.
com.			172800	IN	NS	i.gtld-servers.net.
com.			172800	IN	NS	j.gtld-servers.net.
com.			172800	IN	NS	k.gtld-servers.net.
com.			172800	IN	NS	m.gtld-servers.net.
com.			86400	IN	DS	30909 8 2 
;; Received 1176 bytes from 192.203.230.10#53(e.root-servers.net) in 45 ms

shifen.com.		172800	IN	NS	dns.baidu.com.
shifen.com.		172800	IN	NS	ns2.baidu.com.
shifen.com.		172800	IN	NS	ns3.baidu.com.
shifen.com.		172800	IN	NS	ns4.baidu.com.

;; Received 672 bytes from 192.26.92.30#53(c.gtld-servers.net) in 44 ms

a.shifen.com.		1200	IN	NS	ns4.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns2.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns1.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns3.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns5.a.shifen.com.
;; Received 215 bytes from 202.108.22.220#53(dns.baidu.com) in 28 ms

www.a.shifen.com.	300	IN	A	180.97.33.108
www.a.shifen.com.	300	IN	A	180.97.33.107
a.shifen.com.		1200	IN	NS	ns2.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns3.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns4.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns5.a.shifen.com.
a.shifen.com.		1200	IN	NS	ns1.a.shifen.com.
;; Received 236 bytes from 61.135.165.224#53(ns1.a.shifen.com) in 26 ms
```

仔细观察对比两次 `dig +trace` 会发现第三步时 `shifen.com` 这个顶级域的域名服务器和 `baidu.com` 这个域的域名服务器是同一台主机。

 当拿到 `www.baidu.com` 的别名 `www.a.shifen.com` 的时候，本来需要重新到com域查找 `shifen.com` 域的NS，但是因为这两个域在同一台NS上，所以直接向本机发起了，

`shifen.com` 域发现请求的`www.a.shifen.com` 是属于`a.shifen.com`这个域的，于是就把 `a.shifen.com` 的这个NS和IP返回

用一个图来说明一下
![www.baidu.com查询过程](https://upload-images.jianshu.io/upload_images/14252596-b21dadd1faa9607a.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

总结一下：

1). 本机向 `8.8.8.8 dns` 请求 `www.baidu.com`
2). `8.8.8.8 dns` 向根域请求 `www.baidu.com`，根域返回 `com.` 域的服务器IP
3). 向 `com.` 域请求 `www.baidu.com` ，`com.` 域返回 `baidu.com` 域的服务器IP
4). 向 `baidu.com` 请求 `www.baidu.com`，返回 `cname www.a.shifen.com` 和 `a.shifen.com` 域的服务器IP
5). 向 `root` 域请求 `www.a.shifen.com`
6). 向 `com.` 域请求 `www.a.shife.com`
7). 向 `shifen.com` 请求
8). 向 `a.shifen.com` 域请求
9). 拿到 `www.a.shifen.com` 的IP
10). `8.8.8.8 dns`返回本机 `www.baidu.com cname www.a.shifen.com` 以及 `www.a.shifen.com` 的IP