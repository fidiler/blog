---
title: "Graph Algorithm-Hamilton Path Solution: Part I"
date: "2020-05-26"
categories: ["Algorithm"]
tags: ["Graph Theory"]
---


## 哈密尔顿路径问题
1859年,爱尔兰数学家哈密尔顿(Hamilton) 提出了一个周游世界的游戏

在正十二面体上依次标记伦敦、巴黎、莫斯科等世界著名大城市, 正十二面体的棱表示连接这些城市的路线.
试问能否在图中做一次旅行, 从顶点到顶点, 沿着边行走, 经过每个城市一次之后再回到出发点.

### 哈密尔顿回路
从一个点出发,沿着边行走, **经过每个顶点一次**, 之后**在回到出发点**. 这样走的一条路径叫**哈密尔顿回路**

如下图, 第一张图存在哈密尔顿路径, 因为可以访问每个顶点一次并回到出发点0. 第二张图则不存在哈密尔顿路径



## 哈密尔顿回路求解

一个哈密尔顿回路需要满足两个要求
- 每个顶点都要访问一次
- 能够回到初始顶点

对于这个问题, 可以使用深度优先搜索为框架来解决

首先, 从顶点0出发访问其相邻顶点 (第一个相邻顶点为0)

![](https://upload-images.jianshu.io/upload_images/14252596-287c60ffce85beb7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

由于是深度优先搜索, 接着从1开始访问其相邻顶点2
![](https://upload-images.jianshu.io/upload_images/14252596-12a88e8a5c2d260c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从2访问相邻顶点, **现在要访问0, 但0已经被访问过了**
因此执行到这里满足了哈密尔顿回路的第一个条件: **从起始点回到起始点.**
但并没有满足哈密尔顿回路第二个条件: **所有顶点访问一次**, 这里顶点3还没有访问, 因此执行到这求得的哈密尔顿回路不成立.

当这种条件出现时, 需要**回溯**, 同时将此时访问的顶点标记为没有访问过.

这样做的原因是: 此时搜索的路径是一条死路, 需要回退并重新开始搜索. 
而回退的方式就是利用深度优先搜索的回溯特性, 重新搜索则需要将之前搜索过程中标记的访问的状态置为空.

![](https://upload-images.jianshu.io/upload_images/14252596-277e3ce3d3f7afd3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

回溯到1后, 1还有相邻顶点3没有访问, 因此会访问顶点3

![image.png](https://upload-images.jianshu.io/upload_images/14252596-b9a8c9a9ddf8d66e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从1来到3后, 发生了和从1到2一样的问题: 3的所有相邻节点都访问过了, 并且**回到了起始顶点, 满足了哈密尔顿回路第一个条件,** 但还存在顶点2没有访问过, 因此哈密尔顿回路条件还是不成立.

这时从3回溯到1, 同时将顶点3标记为未访问

![](https://upload-images.jianshu.io/upload_images/14252596-35d16942efdfcd86.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

回溯到1后, 我们发现1的顶点已经全部访问完毕了, 同时哈密尔顿回路的任一条件都没有满足.

因此从1回溯到0, 并将1标记为未访问. 此时问题回到了原点.

这时候上一次从0 -> 1 的深度优先搜索执行完成, 这时候开始访问顶点0的另一个邻边2

![](https://upload-images.jianshu.io/upload_images/14252596-880095d992924002.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

继续执行深度优先搜索, 2首先访问相邻顶点0, 但没满足哈密尔顿回路第二个条件, 于是访问相邻顶点1
![](https://upload-images.jianshu.io/upload_images/14252596-6e3998bacf457396.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

继续执行深度优先搜索, 1首先访问顶点0, 但没满足哈密尔顿回路第二个条件, 于是访问顶点2, 同样也没满足, 最终访问顶点3
![](https://upload-images.jianshu.io/upload_images/14252596-78c086e1e4d3317b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

来到顶点3后, 从顶点3开始执行深度优先搜索, 访问相邻顶点0, 这时候发现0访问过了, **满足了哈密尔顿回路第一个条件, 同时图中所有顶点也有访问过了, 满足了哈密尔顿回路第二个条件,** 因此这条路径满足哈密尔顿回路

![](https://upload-images.jianshu.io/upload_images/14252596-19db4e149cecbbd4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
 
总结一下这个过程:
1. 从某个顶点v出发, 深度优先搜索访问所有相邻顶点
2. 如果相邻顶点w访问过, 但图中的其他顶点还存在没有访问的顶点, 则进行回溯, 并标记v为未访问
3. 回溯到v重复这个过程, 直到满足相邻顶点访问过且其为初始顶点,且图中所有顶点都访问过, 算法执行结果

![](https://upload-images.jianshu.io/upload_images/14252596-bddd9381c4cfb25c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 算法复杂度分析
TODO
### 回溯与剪枝
上面哈密尔顿回路求解的算法, 并不需要遍历所有顶点组成的路径的全排列, 在两个顶点之间没有边的情况下, 那么不会形成一条路径, 也就是剪枝.


![](https://upload-images.jianshu.io/upload_images/14252596-52007090a91c28b9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

对于上图中的图结构， 虽然理论上是全排列生成的。但实际上{2， 3} 之间并没有路径，因此也就不相连。所以在深度优先搜索的过程中，肯定不会去查找包含 2 - 3 这两个顶点的路。
### 实现

下面是求解哈密尔顿回路的基本实现: 使用C++11, 基于深度优先搜索.  图的存储使用了邻接表, 其中表替换成了标准库的`stl::set`

编译: `g++ -std=c++11 hamilton.cc -o hamilton`

```c++
#include <iostream>
#include <vector>
#include <set>
#include <exception>
#include <memory>

// graph data structure use map
class GraphMap {
public:
    GraphMap(int vertexCount, std::vector<std::vector<int>> edges) throw();

    ~GraphMap() = default;

    std::vector<int> adjacency(int v) const;

    inline int V() const { return v_; };

private:
    int v_;
    std::vector<std::set<int>> g_;
};

GraphMap::GraphMap(int vertexCount, std::vector<std::vector<int>> edges) throw() {
    v_ = vertexCount;
    g_ = std::vector<std::set<int>>(vertexCount, std::set<int>());

    for (auto it = edges.begin(); it != edges.end(); it++) {
        auto from = (*it)[0];
        if (from < 0 && from >= vertexCount) {
            throw std::logic_error("invalid vertex");
        }

        int to = (*it)[1];
        if (to < 0 && to >= vertexCount) {
            throw std::logic_error("invalid vertex");
        }


        std::set<int> &set = g_[from];

        // parallel edge
        if (g_[from].find(to) != g_[from].end()) {
            throw std::logic_error("not support parallel edge");
        }

        // self-loop edge
        if (to == from) {
            throw std::logic_error("not support self-loop edge");
        }

        g_[from].insert(to);
        g_[to].insert(from);
    }
}

std::vector<int> GraphMap::adjacency(int v) const {
    std::vector<int> adj;
    std::set<int> gset = g_[v];
    for (auto it = gset.begin(); it != gset.end(); it++) {
        adj.push_back(*it);
    }

    return std::move(adj);
}

class HamiltonLoop {
public:
    explicit HamiltonLoop(std::shared_ptr<GraphMap> g);

    ~HamiltonLoop() = default;

    bool operator()(int s);

private:

    bool dfs(int s, int v);

    bool all_visited();

    std::shared_ptr<GraphMap> g_;

    std::vector<bool> visited_;
};

HamiltonLoop::HamiltonLoop(std::shared_ptr<GraphMap> g) {
    g_ = g;
    visited_ = std::vector<bool>(g_->V(), false);
}

bool HamiltonLoop::operator()(int s) {
    return dfs(s, s);
}

bool HamiltonLoop::dfs(int s, int v) {
    visited_[v] = true;

    std::vector<int> adj = g_->adjacency(v);
    for (int w :  adj) {
        if (!visited_[w]) {
            if (dfs(s, w)) {
                return true;
            }

        } else if (w == s && all_visited()) {
            return true;
        }
    }

    visited_[v] = false;
    return false;
}

bool HamiltonLoop::all_visited() {
    for (bool v : visited_) {
        if (!v) {
            return false;
        }
    }

    return true;
}


int main() {
    int v = 4;
    std::vector<std::vector<int>> edges;
    edges.push_back({0, 1});
    edges.push_back({0, 2});
    edges.push_back({0, 3});
    edges.push_back({1, 2});
    edges.push_back({1, 3});
    try {
        std::shared_ptr<GraphMap> g = std::make_shared<GraphMap>(v, edges);
        HamiltonLoop hamiltonLoop(g);
        std::cout << "has hamilton loop? " << (hamiltonLoop(0) == 1 ? "true" : " false") << std::endl;
    } catch (std::exception &e) {
        std::cout << e.what() << std::endl;
    }
}
```

