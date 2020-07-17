---
title: etcd配置https
date: "2019-04-05"
categories: ["etcd"]
tags: [etcd"]
---



官方推荐使用 cfssl 来自建 CA 签发证书，当然你也可以用众人熟知的 OpenSSL 或者 easy-rsa。以下步骤遵循官方: [Generate self-signed certificates](https://github.com/coreos/docs/blob/master/os/generate-self-signed-certificates.md)

## 生成 TLS 秘钥对

### 下载cfssl

```shell
mkdir ~/bin
curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x ~/bin/{cfssl,cfssljson}
export PATH=$PATH:~/bin
```

### 初始化证书颁发机构

证书类型介绍：

- client certificate 用于通过服务器验证客户端。例如etcdctl，etcd proxy，fleetctl或docker客户端。
- server certificate 由服务器使用，并由客户端验证服务器身份。例如docker服务器或kube-apiserver。
- peer certificate 由 etcd 集群成员使用，供它们彼此之间通信使用。

```shell
mkdir ~/cfssl
cd ~/cfssl
cfssl print-defaults config > ca-config.json
cfssl print-defaults csr > ca-csr.json
```

### 配置CA选项

`ca-config.json`默认包含以下配置字段：

- profiles: www with server auth (TLS Web Server Authentication) X509 V3 extension and client with client auth (TLS Web Client Authentication) X509 V3 extension.
- expiry: 过期时间默认365天

为了规范，将www配置文件命名为server, 使用server auth为client创建对等的配置文件, 并将过期时间设置为5年。

```json
{
    "signing": {
        "default": {
            "expiry": "43800h"
        },
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
```

**ca-csr.json**

```json
{
    "CN": "My own CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "US",
            "L": "CA",
            "O": "My Company Name",
            "ST": "San Francisco",
            "OU": "Org Unit 1",
            "OU": "Org Unit 2"
        }
    ]
}
```



### 生成CA证书

```shell
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
```

将会得到以下几个文件

- `ca-key.pem`
- `ca.csr`
- `ca.pem`

**请务必保证 ca-key.pem 文件的安全，\*.csr 文件在整个过程中不会使用。**

### 生成服务端证书

生成服务端配置文件

`cfssl print-defaults csr > server.json`

```json
{
    "CN": "coreos1",
    "hosts": [
        "192.168.122.68",
        "ext.example.com",
        "coreos1.local",
        "coreos1"
    ],
}
```



或者使用cfssljson

```shell
echo '{"CN":"coreos1","hosts":[""],"key":{"algo":"rsa","size":2048}}' | \
cfssl gencert \ 
-ca=ca.pem \ 
-ca-key=ca-key.pem \
-config=ca-config.json \
-profile=server \ 
-hostname="192.168.122.68,ext.example.com,coreos1.local,coreos1" - | \ 
cfssljson -bare server
```

生成服务端证书

```shell
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare server
```

将得到如下文件

```shell
server-key.pem
server.csr
server.pem
```

### 生成对等端证书

`cfssl print-defaults csr > member1.json`

```json
{
	"CN": "member1",
    "hosts": [
        "192.168.122.101",
        "ext.example.com",
        "member1.local",
        "member1"
    ],
}
```

```shell
cfssl gencert \ 
-ca=ca.pem \ 
-ca-key=ca-key.pem \ 
-config=ca-config.json \ 
-profile=peer member1.json | cfssljson -bare member1
```

或者

```shell
echo '{"CN":"member1","hosts":[""],"key":{"algo":"rsa","size":2048}}' | \ 
cfssl gencert \ 
-ca=ca.pem \ 
-ca-key=ca-key.pem \ 
-config=ca-config.json \ 
-profile=peer \ 
-hostname="192.168.122.101,ext.example.com,member1.local,member1" - | cfssljson -bare member1
```

将得到如下文件

```shell
member1-key.pem
member1.csr
member1.pem
```

### 生成客户端证书

`cfssl print-defaults csr > client.json`

```json
{
    "CN": "client",
    "hosts": [""],
}
```

```shell
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client
```

或者

```shell
echo '{"CN":"client","hosts":[""],"key":{"algo":"rsa","size":2048}}' | \ 
cfssl gencert \ 
-ca=ca.pem \ 
-ca-key=ca-key.pem \ 
-config=ca-config.json -profile=client - | cfssljson -bare client
```

将得到如下文件

```shell
client-key.pem
client.csr
client.pem
```

## 案例

### 用HTTPS的客户端到服务器端传输安全

启动etcd 使用https

```shell
etcd --name etcd-demo --data-dir etcd-demo.etcd \
  --cert-file=$HOME/cfssl/server.pem --key-file=$HOME/cfssl/server-key.pem \
  --advertise-client-urls=https://127.0.0.1:2379 --listen-client-urls=https://127.0.0.1:2379
```

客户端使用ca证书访问

```shell
curl --cacert $HOME/cfssl/ca.pem https://127.0.0.1:2379/v2/keys/foo -XPUT -d value=bar -v
```

该命令应该显示握手成功。 由于我们用自己的证书颁发机构使用自签名证书，CA必须使用`--cacert`选项传递给curl。 另一种可能性是将CA证书添加到系统的可信证书目录（通常位于　`/etc/pki/tls/certs`　或　`/etc/ssl/certs`）中。