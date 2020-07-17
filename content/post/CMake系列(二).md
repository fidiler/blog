---
title: "CMake系列（二）更像工程的Hello World"
date: "2017-08-22"
categories: ["软件开发"]
tags: ["CMake"]
---



# 更像工程的Hello World

本小节的任务是让前面的Hello World更像一个工程，我们需要作的是:
1. 添加一个子目录 src, 用来放置工程源代码;
2. 添加一个子目录 doc, 用来放置这个工程的文档 hello.md
3. 添加一个子目录 bin, 用来放置编译后的二进制
4. 添加一个 hello.sh脚本, 用来调用 hello
5. 将 hello 二进制与 hello.sh 安装至/usr/local/bin

## 编写CMakeLists

在CMake中，需要为任何子目录建立一个 CMakeLists.txt，因此我们在src下添加CMakeLists.txt文件:

```
add_executable(hello main.c)
```
在chapter_2文件夹下新建一个CMakeLists.txt:

```
project(HELLO)

add_subdirectory(src bin)
```

### add_subdirectory指令

`ADD_SUBDIRECTORY(source_dir [binary_dir] [EXCLUDE_FROM_ALL])`

这个指令用于向当前工程添加存放源文件的子目录，并可以指定中间二进制和目标二进制存 放的位置

source_dir 指定源文件目录

binary_dir 指定二进制文件目录

EXCLUDE_FROM_ALL 将这个目录从编译过程中排除

EXCLUDE_FROM_ALL可以在如下的场景中使用:

比如，工程 的 example，可能就需要工程构建完成后，
再进入 example 目录单独进行构建。

## 换个地方保存二进制

我们可以通过 SET 指令重新定义 EXECUTABLE_OUTPUT_PATH 和
LIBRARY_OUTPUT_PATH 变量 来指定最终的目标二进制与共享库的位置

我们想将编译后的目标二进制加入到chapter_2/bin目录下，因此
在chapter_bin/src/CMakeLists.txt添加

`SET(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)`

**问题**

我应该把这两条指令写在 chapter_2 的 CMakeLists.txt 中
, 还是 chapter_2/src 目录下的 CMakeLists.txt 中?

一个简单的原则，在哪里 add_executable 或 add_library，
就在哪里加入上述的定义。

## 安装
在安装前我们需要学习一个新的指令和变量：

### CMAKE_INSTALL_PREFIX变量

CMAKE_INSTALL_PREFIX变量类似于configure脚本的 –prefix，常见的使用方法看
起来是这个样子: `cmake -DCMAKE_INSTALL_PREFIX=/usr .`



### install指令

INSTALL 指令用于定义安装规则，安装的内容可以包括目标二进制、动态库、静态库
以及 文件、目录、脚本等。

#### 目标文件的安装

```
INSTALL(TARGETS targets...
            [[ARCHIVE|LIBRARY|RUNTIME]
                        [DESTINATION <dir>]
                        [PERMISSIONS permissions...]
                        [CONFIGURATIONS
          [Debug|Release|...]]
                        [COMPONENT <component>]
                        [OPTIONAL]
                       ] [...])
```

可以看到install命令很长，不过没关系，我们一一来解释。

TARGETS参数后面跟的就是我们通过 ADD_EXECUTABLE 或者 ADD_LIBRARY 定义的
目标文件，可能是可执行二进制、动态库、静态库。

指定目标文件后，还可以指定目标文件的类型, 分为3种：
- ARCHIVE 特指静态库
- LIBRARY 特指动态库
- RUNTIME 特指可执行目标二进制。

DESTINATION定义了安装的路径，如果路径以/开头，那么指的是绝对路径，
这时候 CMAKE_INSTALL_PREFIX 其实就无效了。如果你希望使用 CMAKE_INSTALL_PREFIX
来定义安装路径，就要写成相对路径，即不要以/开头，那么安装后的路径就是
${CMAKE_INSTALL_PREFIX}/<DESTINATION 定义的路径>

来看一个简单的例子：

```
INSTALL(TARGETS myrun mylib mystaticlib
     RUNTIME DESTINATION bin
     LIBRARY DESTINATION lib
     ARCHIVE DESTINATION libstatic
)
```

上面的例子会将:
- 可执行二进制 myrun 安装到${CMAKE_INSTALL_PREFIX}/bin 目录
- 动态库 libmylib 安装到${CMAKE_INSTALL_PREFIX}/lib 目录
- 静态库 libmystaticlib 安装到${CMAKE_INSTALL_PREFIX}/libstatic 目录

> 你不需要关心 TARGETS 具体生成的路径，只需要写上 TARGETS 名称就可以 了。

> targets与后面的选项一一对应

#### 普通文件的安装

```
INSTALL(FILES files... DESTINATION <dir>
            [PERMISSIONS permissions...]
            [CONFIGURATIONS [Debug|Release|...]]
            [COMPONENT <component>]
            [RENAME <name>] [OPTIONAL])
```

该指令可用于安装一般文件，并可以指定访问权限，文件名是此指令所在路径下的相对路径。
如果 默认不定义权限 PERMISSIONS，安装后的权限为0644,即:
- OWNER_WRITE
- OWNER_READ
- GROUP_READ
- WORLD_READ

DESTINATION 参数与目标文件中的 DESTINATION 参数作用一致

PERMISSIONS 参数用于设定安装后文件的权限，可选项如下：
- OWNER_EXECUTE
- OWNER_WRITE
- OWNER_READ
- GROUP_EXECUTE
- GROUP_READ

CONFIGURATIONS 参数用于控制不同版本的安装

#### 非目标文件的可执行程序安装(比如脚本之类)

```
INSTALL(PROGRAMS files... DESTINATION <dir>
            [PERMISSIONS permissions...]
            [CONFIGURATIONS [Debug|Release|...]]
            [COMPONENT <component>]
            [RENAME <name>] [OPTIONAL])
```

跟上面的 FILES 指令使用方法一样，唯一的不同是安装后权限为755。

#### 目录的安装

```
INSTALL(DIRECTORY dirs... DESTINATION <dir>
            [FILE_PERMISSIONS permissions...]
            [DIRECTORY_PERMISSIONS permissions...]
            [USE_SOURCE_PERMISSIONS]
            [CONFIGURATIONS [Debug|Release|...]]
            [COMPONENT <component>]
            [[PATTERN <pattern> | REGEX <regex>]
             [EXCLUDE] [PERMISSIONS permissions...]] [...])
```

DIRECTORY 参数后面连接的是所在 Source 目录的相对路径，但务必注意:
abc 和 abc/有很大的区别。

如果目录名不以/结尾，那么这个目录将被安装为目标路径下的 abc，
如果目录名以/结尾， 代表将这个目录中的内容安装到目标路径，但不包括这个目录本身。

PATTERN 参数用于使用正则表达式进行过滤

#### 示例
```
INSTALL(DIRECTORY icons scripts/ DESTINATION share/myproj
PATTERN "CVS" EXCLUDE
            PATTERN "scripts/*"
            PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
                    GROUP_EXECUTE GROUP_READ)
```

这条指令的执行结果是:
- 将icons目录安装到 <prefix>/share/myproj，将scripts/中的内容安装到
<prefix>/share/myproj

- 不包含目录名为CVS的目录，对于scripts/*文件指定权限为 OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ.

### 进行安装

**将 hello 二进制与 hello.sh 安装至/usr/local/bin**

我们在chapter_2/CMakeLists.txt中添加

```
install(TARGETS hello RUNTIME DESTINATION bin)

install(PROGRAMS hello.sh
        DESTINATION bin
        PERMISSIONS OWNER_EXECUTE GROUP_EXECUTE)

```

我们在生成Makefile时指定

`cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..`

> 注意 由于目标文件定义在chapter_2/src/CMakeLists.txt中，因此这两条指令需要写在add_subdirectory后

**疑问**

没有定义CMAKE_INSTALL_PREFIX，默认会安装到哪里，答案是 `/usr/local`

## 小结

本节我们介绍了以下指令
- add_subdirectory
- install

介绍了以下变量
- EXECUTABLE_OUTPUT_PATH
- LIBRARY_OUTPUT_PATH

通过本节，我们有了使用CMake构建工程的初步概念