---
title: "基础的UDP编程"
date: "2018-03-01"
categories: ["网络编程"]
tags: ["udp"]
---


在编写UDP网络程序时，和编写TCP的网络程序有本质差异，其区别在于UDP是**无连接**、**不可靠**的传输协议。
当然相信这句话你可能已经听烂了，UDP不会建立连接（也可以调用`connect`），因此UDP的数据传输不是字节流，而是数据报。
字节流就像水管一样源源不断的流向另一端，而数据包就像携带数据的 “包裹” 一样，发出去就结束了。理解在进行数据传输时，UDP和TCP以不同的形式传输有助于我们
编写UDP网络程序。


## UDP编程模型（套路）
和TCP一样，在编写UDP程序时，也遵循一些模型（套路），也就是内核提供的相关的系统调用
![UDP基础编程模型.jpg](https://upload-images.jianshu.io/upload_images/14252596-eb44607209b54cf3.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

上图展示了一个非常基础的UDP编程模型
服务端（server）会有以下步骤
1. 调用 `socket` 系统调用创建socket文件描述符
2. 调用 `bind`系统调用绑定IP地址和端口，IP地址和端口应该是众所周知的
3. 进入主循环, 调用`recvfrom` 系统调用等待client发送请求
4. 等到client发送请求，处理请求，之后调用 `sendto`应答

客户端（client）会有以下步骤
1. 调用 `socket` 系统调用创建socket文件描述符
2. 调用 `sendto`系统调用像server发送请求
3. 等待server回复
4. 调用 `close` 关闭文件描述符（实际是释放socket创建的文件描述符，并不是真正的连接）

可以看到，UDP的模型中，并不像TCP建立连接，进行三次握手，然后保持连接进行双方通信，更像一来一回的方式通信。

## recvfrom 和 sendto 函数
在前面描述的UDP编程中，提到了两个新的函数 `recvfrom` 和 `sendto`, 来看一下这两个函数在linux中的定义
```c
#include <sys/types.h>
#include <sys/socket.h>
ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags,
                        struct sockaddr *src_addr, socklen_t *addrlen);
```

`recvfrom` 函数用于从面向无连接 (UDP) 的`socket` 接收信息。
该函数的参数理解如下：
1. `int sockfd` socket函数创建的文件描述符
2. `void *buf`  接收到的数据会写入到buf中
3. `size_t len` 指明`buf`的大小
4. `int flags` 我们在后续的高级UDP编程中讨论，暂时使用 `0` 值
5. `struct sockaddr *src_addr` 发送方的信息会保存到该参数中，并随着调用一起返回
6. `socklen_t *addrlen`  发送方的信息地址的长度会保存到该参数中，并随着调用一起返回

```c
#include <sys/types.h>
#include <sys/socket.h>
ssize_t sendto(int sockfd, const void *buf, size_t len, int flags,
                      const struct sockaddr *dest_addr, socklen_t addrlen);

```
`sendto` 函数像从面向无连接 (UDP) 的`socket` 发送信息。
该函数的参数理解如下：
1. `int sockfd` socket函数创建的文件描述符
2. `const  void *buf`  发送的数据
3. `size_t len` 指明发送数据**实际的大小**
4. `int flags` 我们在后续的高级UDP编程中讨论，暂时使用 `0` 值
5. `const  struct sockaddr *dest_addr` 要发送的目的地的地址结构
6. `socklen_t *addrlen`  指明该地址结构的大小

`recvfrom` 和  `sendto` 在参数上结构上类似，需要注意的是 `recvfrom`的 `void *buf` 并不是const类型的，其原因是需要拷贝数据到该buf中，而在`sendto`中则是const类型的，是因为该数据内核只需要读取并发送给对方。
`recvfrom` 中的 `socklen_t *addrlen` 是一个指针类型，因为函数调用在**返回发送发地址**的时候会往该参数中写入长度。
`recvfrom` 中的 `struct sockaddr *src_addr, socklen_t *addrlen` 这两个参数为空，为空表示接收者不关心发送方的地址信息。

**发送长度为0的数据报**
发送为0的数据报在UDP中是可行的，这样的数据包只会包含**IP首部（ipv4 20字节 ipv6 40字节）**和 **UDP首部（8字节）** 。
这就意味着对于`recvfrom` 返回0值是可以的，但对于 TCP来说，`read`返回0值意味着对端已经关闭连接。
## UDP Server
在了解了UDP编程所须的基础后，下面简单的写一个 `udp echo server`, 该server接收客户端发送的数据报，并 `echo` 回去，下面是 `udp server`的实现
```c
#include "udp.h"

static void _dg_echo(int fd, struct sockaddr * p_cli_addr, socklen_t cli_addr_len);

int main() {
    int sockfd;
    sockfd = socket(AF_INET,SOCK_DGRAM,0);
    if (sockfd == -1) {
        printf("%s\n", "create socket error");
        exit(0);
    }

    struct sockaddr_in serv_addr, cli_addr;
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    serv_addr.sin_port = htons(SERV_PORT);

    if (bind(sockfd, (const struct sockaddr *)&serv_addr, sizeof(serv_addr)) == -1) {
        printf("%s\n", "bind error");
        exit(0);
    }

    _dg_echo(sockfd, (struct sockaddr *)&cli_addr, sizeof(cli_addr));
    
    return 0;
}

static void _dg_echo(int fd, struct sockaddr * p_cli_addr, socklen_t cli_addr_len) {
    int n;
    char recv_line[1024];
    socklen_t len;
    for (;;) {
        len = cli_addr_len;
        n = recvfrom(fd, recv_line, 1024, 0, p_cli_addr, &len);
        sendto(fd, recv_line, n, 0, p_cli_addr, len);
    }
}
```
该程序并不像 TCP 那样通过 `fork` 、`select`、`pthread`等手段变成并发服务器，它是一个迭代服务器，大多数情况下UDP服务器也都是迭代的。

`client`端代码
```c
#include "udp.h"

static void _dg_cli(int fd, const struct sockaddr * p_serv_addr, socklen_t serv_addr_len);

int main(int argc, const char *argv[]) {
    int sockfd;
    if (argc != 2) {
        printf("udpc <ipv4>\n");
        exit(0);
    }

    struct sockaddr_in serv_addr;
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(SERV_PORT);
    inet_pton(AF_INET, argv[1], &serv_addr.sin_addr);

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        printf("create sock error\n");
        exit(0);
    }

    _dg_cli(sockfd, (const struct sockaddr *)&serv_addr, (socklen_t)sizeof(serv_addr));
  
    return 0;
}

static void _dg_cli(int fd, const struct sockaddr * p_serv_addr, socklen_t serv_addr_len) {
    int n;
    char send_line[1024], recv_line[1025];
    while(fgets(send_line, 1024, stdin) != NULL) {
        sendto(fd, send_line, strlen(send_line), 0, p_serv_addr, serv_addr_len);
        n = recvfrom(fd, recv_line, 1024, 0, NULL, NULL);
        recv_line[n] = 0;
        fputs(recv_line, stdout);
    }
}
```
`udp.h`代码
```c
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#define SERV_PORT 3123
#define MAXLINE 1024

```
**UDP缓冲区**
上述的代码，UDP层实际上是隐含排队的。对于每个套接字，它会有一个接收缓冲区，`sendto`发出的UDP数据报都会进入该缓冲区，该缓冲区是一个 FIFO的模式，当缓冲区满时，`sendto`发出的数据报会被丢弃，`recvfrom` 会从缓冲区获取数据报。
> 缓冲区是有大小限制的，但也是可以调整的，关于如何调整大小，在后续介绍。

**数据报丢失**
我们前面的代码中，如果`_dg_cli` 函数中 `sendto` 发送的数据报丢失了，那么客户端将一直阻塞在 `recvfrom`中。如果客户端发送数据报到服务端了，但服务端的 `sendto`丢失了，客户端还是会阻塞在 `recvfrom`中，一种解决办法是为`recvfrom`增加**超时时间**，但这不是一个完整的解决方式，因为无法弄清是客户端没有发送数据报还是服务端应答丢失了。

## UDP中的一些问题
**需要验证服务端的应答**

为什么需要验证服务端的应答呢？因为UDP是无连接的，客户端可能收到其他客户端发来的数据报，这样就影响了正常的服务端应答，我们可以记住服务端的应答，忽略其他。
因此客户端代码修改如下
```c
// udp_cli_02.c

#include "udp.h"

static void _dg_cli(int fd, const struct sockaddr * p_serv_addr, socklen_t serv_addr_len);

int main(int argc, const char *argv[]) {
    int sockfd;
    if (argc != 2) {
        printf("udpc <ipv4>\n");
        exit(0);
    }

    struct sockaddr_in serv_addr;
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(SERV_PORT);
    inet_pton(AF_INET, argv[1], &serv_addr.sin_addr);

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        printf("create sock error\n");
        exit(0);
    }

    _dg_cli(sockfd, (const struct sockaddr *)&serv_addr, (socklen_t)sizeof(serv_addr));
  
    return 0;
}

static void _dg_cli(int fd, const struct sockaddr * p_serv_addr, socklen_t serv_addr_len) {
    int n;
    socklen_t len = serv_addr_len;
    char send_line[1024], recv_line[1025];
    struct sockaddr *p_replay_addr = malloc(serv_addr_len);
    while(fgets(send_line, 1024, stdin) != NULL) {
        sendto(fd, send_line, strlen(send_line), 0, p_serv_addr, serv_addr_len);
        n = recvfrom(fd, recv_line, 1024, 0, p_replay_addr, &len);
        if (len != serv_addr_len || memcmp(p_serv_addr, p_replay_addr, len) != 0) {
            printf("server reply ignored.\n");
            continue;
        }
        recv_line[n] = 0;
        fputs(recv_line, stdout);
    }
}
```
上面的客户端程序相比前面的程序从`recvfrom`拿到了服务端发送的地址，然后与之前的服务端地址进行比较，如果不同则忽略。

**异步错误**

假如调用`sendto`往一个已关闭的客户端发送信息会怎么样? 
会引起一个**异步错误**，服务端会响应一个`port unreachable` 的ICMP消息，该消息是由`sendto`造成的，错误原因是因为在发送数据包之前， 会调用ARP信息获取对端的`mac`地址，但由于服务器已经关闭，因此会得到一个**端口不可达**的ICMP消息。
尽管这个错误是由`sendto`引起，但`sendto`不会返回错误信息，`sendto`实际上返回的成是**在缓冲区队列形成IP数据报的空间**的成功。而ICMP消息后续才到来，这也是说异步错误的原因所在。

## UDP的connect函数

UDP的`connect` 不同于 TCP的connect函数，它没有三次握手过程，但可以检查到**异步错误（例如端口不可达）**
在UDP使用了`connect`之后，和之前的UDP程序编写可能不同，不需要在调用`sendto` 了，因为已经指定好了地址和端口号，而是要改用 `send`和`write`
> 但还是可以使用 `sendto`，只是`sendto`的 第五个参数目的地地址为空指针，目的地地址长度为0

对于`recvfrom`，要改用 `recv`，`read`或`recvmsg`。
对于调用 `connect` 的UDP连接来说，内核会限制该UDP套接字只能与它连接的对端交换数据，对于其他端发送的数据会忽略。
下面我们用connect改写之前的客户端程序。
```c
#include "udp.h"
#include <errno.h>

// extern int errno;

static void _dg_cli(int fd, const struct sockaddr * p_serv_addr, socklen_t serv_addr_len);

int main(int argc, const char *argv[]) {
    int sockfd;
    if (argc != 2) {
        printf("udpc <ipv4>\n");
        exit(0);
    }

    struct sockaddr_in serv_addr;
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(SERV_PORT);
    inet_pton(AF_INET, argv[1], &serv_addr.sin_addr);

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        printf("create sock error\n");
        exit(0);
    }

   


    _dg_cli(sockfd, (const struct sockaddr *)&serv_addr, (socklen_t)sizeof(serv_addr));
  
    return 0;
}

static void _dg_cli(int fd, const struct sockaddr * p_serv_addr, socklen_t serv_addr_len) {
    if (connect(fd, p_serv_addr, serv_addr_len) == -1) {
        printf("connect error: %s\n", strerror(errno));
        exit(0);
    }

    int n;
    char send_line[1024], recv_line[1025];
    while(fgets(send_line, 1024, stdin) != NULL) {
        if (write(fd, send_line, strlen(send_line)) == -1) {
            printf("write error: %s\n", strerror(errno));
            continue; 
        }

        if ((n = read(fd, recv_line, 1024))== -1) {
            printf("read error: %s\n", strerror(errno));
            continue;
        }
        
        recv_line[n] = 0;
        fputs(recv_line, stdout);
    }
}
```
上面的代码使用了 `connect` 连接UDP，之后使用 `read` `write` 读写，如果对端服务器关闭，我们在`write`的时候会得到 `Connection refused` 错误。

## UDP丢包问题
修改了之前客户端 `_dg_cli` 代码，让客户端每次发送1400byte的数据，发送10w次，同时修改客户端代码，统计`recvfrom`接收到的数据条目。

```c
// _dg_cli
    int i ;
    socklen_t len = serv_addr_len;
    char send_line[1024];

    for (i = 0; i < 100000;i++) {
        if (sendto(fd, send_line, 1024, 0, p_serv_addr, serv_addr_len) == -1) {
            printf("sendto error: %s\n", strerror(errno));
            continue;
        }
    }      
```

```c
// udp_serv_02.c
static int count;
static void recvfrom_count(int signo);

static void 
_dg_echo(int fd, struct sockaddr * p_cli_addr, socklen_t cli_addr_len) {
    signal(SIGINT, recvfrom_count);

    int n;
    char recv_line[1024];
    socklen_t len;
    for (;;) {
        len = cli_addr_len;
        recvfrom(fd, recv_line, 1024, 0, p_cli_addr, &len);
        count++;
    }
}


static void
recvfrom_count(int signo) 
{
    printf("received %d datagrams\n", count);
    exit(0);
}
```
然后我们启动客户端和服务端程序，得到结果如下

```shell
➜  udp ./udps                                                                                                                                                                   
 ^Creceived 98182 datagrams
```
会发现出现了丢包，因为UDP是无连接的，属于不稳定的传输协议，当接收套接字的接收队列已满数据报就会被丢弃。

使用 `netstat -s -p udp` 可以查看UDP发送数据包的情况

## 小结
1. 我们首先介绍了基本的UDP编程步骤，UDP不同于TCP，不需要建立连接，只需要对方地址交换数据报

2. UDP可以发送长度为0的数据报，这就意味着接收端读到0字节是合法的

3. UDP在往一个已关闭的服务器发送数据时不会出错，因为这个错误时异步的错误

4. UDP也可以调用`connect`，不过这不同于TCP，UDP调用该函数后只能与指定的端进行通信，同时可以调用 `read`，`write`等函数来收发数据，同时可以立即接收到异步错误，比如端口不可达，`connect`一般由客户端调用

5. UDP容易丢包，一旦缓冲区队列已满，UDP会丢弃发送的数据报
