---
title: 认识Google Protocol Buffer
date: "2018-10-02"
categories: ["软件开发"]
tags: ["grpc","protobuffer"]
---



Protocol Buffer 是 Google 公司内部的混合语言数据标准，常用于数据存储和RPC。

Protocol Buffer 可以用于结构型数据序列化。可用于通讯协议、数据存储等领域的语言无关、平台无关、可扩展的序列化结构数据格式。提供了多种语言的API。

## e.g

```c
syntax = "proto3"

message SearchRequest {
	string query = 1;
	int32 page_number = 2;
	int32 result_per_page = 3;
}
```

- 第一行指定了当前使用的语法为 `proto3`，当然也可以使用 `proto2` 表示版本2的语法。
- 余下部分定义了消息，有3个字段组成， 每个字段都需要有类型和名称

## 字段类型

上面的类型使用了两个标量类型 `string` 和 `int32`， 当然还支持其他类型，见附录

## 字段编号

在上面了类型中，每个字段都分配了一个唯一编号，这里主要用于标识消息序列化后在二进制时的格式的字段， 并且在使用后不要更改。

1-15编号的字段使用一个字节编码（字段编号+类型）， 16 ~ 2047编号的字段占用两个字节，频繁出现的字段应该使用 1 ~ 15的编号。

最小字段编号为1， 最大为 `2^29 - 1`, 需要注意的是 **19000到19999** 不能使用，这些编号在 `.proto` 中是默认保留的

## 添加更多的消息

在定义一组相关的消息时，可以将多个消息定义在一个 `.proto` 文件中，比如想定义搜索后的响应消息：

```c
message SearchRequest {
  string query = 1;
  int32 page_number = 2;
  int32 result_per_page = 3;
}

message SearchResponse {
 ...
}
```

## 添加注释

注释风格可以是 `//` 或者 `/*...*/`

比如为之前的消息添加注释:

```c
/* SearchRequest represents a search query, with pagination options to
 * indicate which results to include in the response. */

message SearchRequest {
  string query = 1;
  int32 page_number = 2;  // Which page number do we want?
  int32 result_per_page = 3;  // Number of results to return per page.
}
```

## 保留字段

当我们想修改一个`.proto` 文件内定义的消息时，如果删除或者注释掉了某个字段，如果后面加载相同的旧版本的 `.proto`文件，可能会导致数据损坏等一些Bug.

`protocol buffer` 为我们提供了一种解决这个问题的办法，就是保留已删除字段的字段编号或名称。 如果后面尝试使用这些保留字段标识符，`protocol buffer` 编译器将会报错。

e.g.

```c
message Foo {
  reserved 2, 15, 9 to 11;
  reserved "foo", "bar";
}
```

消息 `Foo` 中，我们保留了 2, 15以及9-11编号的字段和 foo、bar 两个以名称表示的字段， `to` 关键字可以指定区间。

注意： 不能在同一行中同时使用编号和名称。

## 生成消息对应的代码

当运行 `protocol buffer` 编译器编译一个 `.proto`文件时，可以根据定义的消息生成对应语言的代码，这些代码包括：

- set和get字段值
- 将消息序列化为output stream
- 将input stream解析为消息

## 默认值

- string: 空值
- bytes: 空字节
- bool: false
- 数字类型: 0
- enum: 默认值是第一个定义的值，必须为0

## 枚举类型

当定义一个message时，可能希望定义一系列的预定义的语意值列表，例如为之前的`SearchRequest` message 添加搜索类型，其中可以是UNIVERSAL，WEB，IMAGES，LOCAL，NEWS，PRODUCTS或VIDEO。这样可以通过在消息中定义枚举类型来实现。

## 生成grpc对应rpc代码

```c
message SearchRequest {
  string query = 1;
  int32 page_number = 2;
  int32 result_per_page = 3;
  enum Corpus {
    UNIVERSAL = 0;
    WEB = 1;
    IMAGES = 2;
    LOCAL = 3;
    NEWS = 4;
    PRODUCTS = 5;
    VIDEO = 6;
  }
  Corpus corpus = 4;
}
```

可以看到，上面的消息中，enum的第一个常量必须是零值，这是因为必须要有一个零值作为默认值。

也可以为不同的枚举常量指定相同的值来定义别名，只需要设置 `allow_alias = true`， 如果不设置，编译器在查找时将出现错误

```c
enum EnumAllowingAlias {
  option allow_alias = true;
  UNKNOWN = 0;
  STARTED = 1;
  RUNNING = 1;
}
enum EnumNotAllowingAlias {
  UNKNOWN = 0;
  STARTED = 1;
  // RUNNING = 1;  // Uncommenting this line will cause a compile error inside Google and a warning message outside.
}
```

## 其他类型

### repeated

在上面定义了一个`SearchResponse` message, 假如搜索响应结果中包含多个 `Result` message, 我们可以这样做：

```c
message SearchResponse {
  repeated Result results = 1;
}

message Result {
  string url = 1;
  string title = 2;
  repeated string snippets = 3;
}
```

这样`SearchResponse`中就可以包含多个`Result`

### import

可以通过 import导入其他 `.proto` 文件来使用其中的定义。例如：

```
import "myproject/other_protos.proto";
```

默认情况下，只能使用导入的`.proto`文件中的定义，然而，一些情况下你可能移动 `.proto`文件到新的位置。这种情况可以在旧位置放置一个 `.proto` 文件，通过 `import public` 将该文件转发到新的位置。例如：

```c
// new.proto
// 所有的定义都移动到这里
```

```c
// old.proto
// 这里是所有旧的客户端都需要引用的文件
import public "new.proto";
import "other.proto";
```

```c
// client.proto
import "old.proto";
// client可以使用old.proto和new.proto中的定义，但不能使用other.proto
```



### 嵌套类型

类似上文中的 `SearchResponse`可以使用如下的方式定义:

```c
message SearchResponse {
  message Result {
    string url = 1;
    string title = 2;
    repeated string snippets = 3;
  }
  repeated Result results = 1;
}
```

也可以将消息进行组合，例如：

```c
message SomeOtherMessage {
  SearchResponse.Result result = 1;
}
```

可以根据需求进行深度嵌套:

```c
message Outer {                  // Level 0
  message MiddleAA {  // Level 1
    message Inner {   // Level 2
      int64 ival = 1;
      bool  booly = 2;
    }
  }
  message MiddleBB {  // Level 1
    message Inner {   // Level 2
      int32 ival = 1;
      bool  booly = 2;
    }
  }
}
```

### Any

`Any` 允许不声明类型，用来作为任意消息的字节。要使用`Any` 需要先引入

```c
import "google/protobuf/any.proto"
```

```c
import "google/protobuf/any.proto";

message ErrorStatus {
  string message = 1;
  repeated google.protobuf.Any details = 2;
}
```



## 附录

### proto命令

| 选项        | 含义               | 示例                                |
| ----------- | ------------------ | ----------------------------------- |
| –proto_path | .proto文件所在路径 | –proto_path=IMPORT_PATH             |
| –cpp_out    | 生成c++代码        | –cpp_out=DST_DIR path/to/file.proto |
| –java_out   | 生成java代码       |                                     |
| –python_out | 生成python代码     |                                     |
| –go_out     | 生成go代码         |                                     |
| –ruby_out   | 生成ruby代码       |                                     |
| –objc_out   | 生成object-c代码   |                                     |
| –csharp_out | 生成c#代码         |                                     |

### proto数据结构

### proto类型

| .proto类型 | 备注                                                         | c++    | java    | python      | go      | php            |
| ---------- | ------------------------------------------------------------ | ------ | ------- | ----------- | ------- | -------------- |
| double     |                                                              | double | double  | float       | float32 | float          |
| float      |                                                              | float  | float   | float       | float64 | float          |
| int32      | int32使用可变长度编码，编码负数的效率比较低，如果负数应该使用 sint | int32  | int     | int         | int32   | integer        |
| int64      |                                                              | int64  | long    | int/long    | int64   | integer/string |
| uint32     |                                                              | uint32 | int     | int/long    | uint32  | integer        |
| uint64     |                                                              | uint64 | long    | int/long    | uint64  | integer/string |
| sint32     |                                                              | int32  | int     | int         | int32   | integer        |
| sint64     |                                                              | int64  | long    | int/long    | int64   | integer/string |
| fixed32    | 总是4字节编码，如果值大于2^28，建议使用此类型                | uint32 | int     | int/long    | uint32  | integer        |
| fixed64    | 总是4字节编码，如果值大于2^56，建议使用此类型                | uint64 | long    | int/long    | uint64  | integer/string |
| sfixed32   |                                                              | int32  | int     | int         | int32   | integer        |
| sfixed64   | 总是8字节编码                                                | int64  | long    | int/long    | int64   | integer/string |
| bool       |                                                              | bool   | boolean | bool        | bool    | boolean        |
| string     | 包含UTF-8编码或7位ASCII文本。                                | string | String  | str/unicode | string  | string         |