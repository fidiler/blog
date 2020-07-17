---
title: "初识NAT协议"
date: "2018-03-08"
categories: ["计算机网络"]
tags: ["ip","dns"]
---



IP地址只有32位，只有42.9亿个地址，如果去掉保留地址、组播地址，能用得只有36亿左右，如果没有NAT技术，IP地址可能早就用光。

NAT可以提供本地私有地址和全局地址的转换。除了可以转换IP地址外，还出现了可以转换TCP、UDP端口号的NAPT（Network Address Ports Translator）技术，由此可以实现用一个全局IP地址与多个主机的通信。

NAT（NAPT）也提高了网络安全：**把洪水猛兽挡在门外就安全了**，因此在IPv6中为了提高网络安全也在使用NAT，在IPv4和IPv6之间的相互通信当中常常使用NAT-PT。




# NAT的工作原理

我们知道同一局域网内的IP可以互相访问，那么公网是否可以访问内网呢？答案是不可以，所以需要NAT（静态），同样内网是也不可以访问公网，需要NAT（动态）把内网私有IP转换为公网IP。

![NAT](https://upload-images.jianshu.io/upload_images/14252596-df5277e5f558445b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


如图，以10.0.0.10的主机与163.221.120.9的主机进行通信为例。

往公网发送数据：
利用NAT，途中的NAT路由器将发送源地址从10.0.0.10转换为全局的IP地址（202.244.174.37）后再发送数据。

公网往私网返回数据：
当包从地址163.221.120.9发过来时，NAT会将目标地址（202.244.174.37）先被转换成私有IP地址10.0.0.10之后再转发

有一个疑问，当NAT收到公网发出的数据时，怎么知道转发给那个内网主机呢？
答案是，在NAT（NAPT）路由器的内部，有一张自动生成的用来转换地址的表。
当10.0.0.10向163.221.120.9发送第一个包时生成这张表，并按照表中的映射关系进行处理。

> 在TCP的情况下，建立TCP连接首次握手时的SYN包一经发出，就会生成这个表。而后又随着收到关闭连接时发出FIN包的确认应答从表中被删除

# NAPT
当私有网络内的多台机器同时都要与外部进行通信时，仅仅转换IP地址，不免担心全局IP地址是否不够用。
NAPT采用IP+端口号一起转换的方式（NAPT）可以解决这个问题。

![NAPT](https://upload-images.jianshu.io/upload_images/14252596-a7ac8a24fefd51d2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

# NAT存在的问题
1. 转换表的生成与转换操作都会产生一定的开销
2. 通信过程中一旦NAT遇到异常需重新启动时，所有的TCP连接都将被重置
3. 即使备置两台NAT做容灾备份，TCP连接还是会被断开

# NAT穿越
NAT穿越是指使用了NAT设备的私有主机与TCP/IP网络中的主机之间建立连接的问题。

具体应该如何实现呢？

假设有一台服务器S，两台处于不同内网的主机A和B
![NAT穿越过程](https://upload-images.jianshu.io/upload_images/14252596-541f6ac84a45ca26.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

如图
1. A和B都像S发送消息
2. S转发A的消息（ip + port）给B，S转发B的消息（ip + port）给A，于是A、B都知道的对方的地址
3. A发消息给B，B会屏蔽掉这条消息，但是在A的NAT映射上加上了一条映射，允许A接收来自B的消息
4. B发消息给A，A可以收到消息，同时在B的NAT映射上加了一条映射，允许B接收来自A的消息
5. 完成穿越