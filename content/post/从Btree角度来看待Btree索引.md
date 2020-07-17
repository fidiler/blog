---
title: "从BTree角度来看待BTree索引"
date: "2019-03-02"
categories: ["数据库","数据结构","操作系统"]
tags: ["btee"]
---

在深入学习mysql索引优化这一章节时，我们需要学习以下知识点:

- disk和disk的结构
- data如何在磁盘上store和reference
- index
- b-tree

# disk

磁盘由盘片组成的，每个盘片称为表面，表面覆盖磁性记录材料，如图下图所示：

![img](/images/磁盘结构.png)

每个表面有多个磁道，每个磁道又划分为多个扇区，扇区包含相等数量的数据位，通常为512bytes.

扇区之间存在一些间隙，间隙中不存储数据位。间隙存储用来标识扇区的格式化位。

磁盘表面结构如下图所示：

![img](/images/磁盘盘面结构.png)

# 数据库数据如何在磁盘上存储的

我们假设有一张Employee表，记录了员工信息，它的数据库字段如下：

- eid — 10bytes
- name — 50bytes
- dept — 10bytes
- sed — 8bytes
- add — 50bytes

那么这个表一行记录的大小就是128bytes, 假如扇区的大小为512bytes,那么一个扇区可以存储 **512(bytes)/128(bytes) = 4(rows)**。如图所示：

![img](/images/磁盘存储数据库数据.png)

假设我们有100(rows)的数据，则需要 **100(rows) / 4(rows) = 25(blocks)** 个扇区来存储。

# 对磁盘数据索引

为了帮助程序快速的找到磁盘中的数据，我们需要对磁盘数据建立索引，一个最简单的方法是，根据 某一列做索引，并把索引存储在一个向量中。如图所示：

![img](/images/数据在磁盘中的索引.png)

我们对`cid` 字段做了索引，并有一个`pointer` 指向对应在磁盘中的数据。

那么加入我们查找一个 `cid = 1` 的行，会是什么操作呢，一种最理想的情况是 O(1), 但实际上大部分的情况下时间复杂度都是 `O(N)`。

对于O(N)的时间复杂度，在表的数据较小的情况下是可以忍受的，但在表数据比较大的情况下，O(N)的复杂度实际上是非常慢的。

对于空间复杂度，也是O(N)。

我们能非常轻松想到的一点就是数据使用二叉树存储，并使用二分查找来搜索，这样空间和时间复杂度都是O(logn), 但是二叉树存储有可能出现斜树，一旦出现了较长的斜树，那么就不能保证还是O(logn)的复杂度，因此需要对二叉树进行平衡。

于是我们就想到一个数据结构AVL-Tree, 我们使用AVL来存储索引，它的结构如下图：

![img](/images/AVL-Tree index.png)

但AVL-Tree有以下缺点：

- 旋转耗时
- 适合插入和删除次数较少，但查询多的情况

但在数据库系统中，插入和删除是不能妥协的功能，另外还有一点，AVL-Tree在大数据量的情况下**层数较多**，因此就算是AVL-Tree适合查找，但由于磁盘I/O的效率是非常低的，我们需要避免大量的磁盘I/O就需要减少层数，这就引出了另一个数据结构**B-Tree**。

# B-Tree

B-Tree是一种特殊的平衡查找树，专门为存储设备设计，多用于数据库系统中。

一棵m(m≥3)阶的b-tree,满足以下几个性质：

1. 每个结点至少包含下列信息域（n, p0,k1,p2,k2, …, pn, kn）,n表示关键字的个数，ki (1 ≤ 1 ≤ n) 为关键字，且**ki < ki + 1 (1 ≤ i ≤ n);** pi (0 ≤ i ≤ n) 为指向子树根结点的指针,且pi所指向的子树中的所有结点的关键字均小于ki + 1，pn所指子树中的所有结点的关键字均大于kn;
2. 若树为非空，则根结点至少有1个关键字，至多有m-1个关键字。因此，若根结点不是叶子结点，则它至少有两棵子树。
3. 树中每个结点至多有m棵子树。
4. 叶子的层数为树的高度h
5. 每个非根结点所包含的关键字个数满足：[m/2] - 1 ≤ n ≤ m -1。因此，除根结点之外的所有非终端结点（叶子结点的最下层结点称为终端结点）至少有[m/2]棵子树，至多有m棵子树。

下图是一棵4阶的B-Tree:

![img](/images/4阶B-Tree.png)

该数高度为3，所有叶子结点在第3层上。在一棵4阶的b-tree中，每个结点的关键字最少为 [m/2] - 1 = [4/2] - 1= 1

最多为 m - 1 = 4 - 1 =3; 每个结点子树个数最少为 [m/2] = [4/2] = 1, 最多为 m = 4;

关键字向量中，key[0]不用来存储关键字。

## B-Tree 插入操作

b-tree的插入操作不是在树中添加一个结点，而是现在最低层的某个非终端结点中添加一个关键字。若该结点中的关键字个数 ≤ m - 1, 则插入完成，否则就会引起分裂。

分裂操作：

分裂结点时把结点拆分成两部分，将中间的一个关键字拿出来插入到该结点的双亲结点上，如果双亲结点中的关键字个数 = m - 1, 则插入结点也会引起双亲结点的分裂，这一过程可能波及到b-tree的root结点，从而让树长高一层。

假设有以下关键字序列: `24，45，53，70，3，50，30，61，12，70，100`，生成一棵4阶的b-tree

插入过程如下图所示:

![img](/images/4阶B-Tree插入过程.png)

当前三个关键字：24，45，53进行插入时，既是root结点也是叶子结点.

当插入90时，会引发分裂

当插入61，12时，同样会引发分裂

当插入100时，分裂会影响到root结点，从而树增高一层

## B-Tree 删除操作

b-tree上进行删除会引发合并。

1.若删除的关键字所在结点中的关键字数目不小于[m/2], 则只需删除该结点中的关键字和指针p。

如图所示，删除关键字3

![img](/images/B-Tree删除结点(1).png)

2.若删除的关键字所在结点中关键字数目等于[m/2] -1,即关键字数目已是最小值， 直接删除的话会破坏b-tree的性质

3.当出现（2）所描述的情况，首先判断所删除结点的左（或者右）邻兄弟结点的关键字数目是否不小于[m/2], 如果满足，执行下面的操作：

- 将兄弟结点中最大（或最小）的关键字上移到双亲结点中
- 将双亲结点中响应的关键字移至删除结点中。

显然删除完成后，双亲结点的关键字数目不变。

如图所示，删除关键字8之后，右邻兄弟结点中的最小值移动至双亲结点中，双亲结点关键字移动至删除结点。

![img](/images/B-Tree删除结点(2、3).png)

4.若删除关键字所在结点及其相邻的左、右兄弟（或只有一个兄弟）结点关键字数目均等于[m/2] -1 ，则（3）所描述的操作就不能实现。此时，需要将被删除结点和其兄弟结点进行**合并**。

合并操作：假设删除的关键字所在结点有右邻兄弟（对左邻兄对方法类似），其兄弟结点的地址由双亲结点中的指针pi指定，删除关键字之后，它所在结点中**剩余的指针加上双亲结点中的关键字ki一起合并到pi指定的兄弟结点中。**

如图所示，当删除关键字50时，右邻兄弟和关键字所在结点均等于[m/2] - 1, 此时会触发合并，删除关键字后，关键字指针和双亲结点关键字53合并到右邻兄弟结点。

![img](/images/B-Tree删除结点(4).png)

如果合并操作引起对父结点中关键字删除，又可能需要合并结点，这一过程可能波及到根结点，引起根结点对关键字的删除，从而使b-tree高度降低一层。

如图所示，删除关键字12之后，会引发两次合并，波及到root结点，树的高度降低一层。

![img](/images/B-Tree删除结点导致树的高度降低.png)

## B-Tree查找操作

根据b-tree的定义，b-tree的查找与二叉排序树类似，都是经过一条从树根结点到待查关键字所在结点的查找路径。

和二叉排序树不同的是，对路径中的每个结点的比较过程比在二叉排序树中的情况下复杂一些，通常需要经过与多个关键字比较后才能处理完一个结点，因此b-tree查找又成为多路查找树

查找算法：从根结点开始，若b-tree非空，首先取出根结点，将给定k值一次与关键字比较从高到低比较

直到 k ≥ ki ，如果k = ki且 ki 大于0，则表示查找成功，否则从i开始，向下层查找。

如图所示的一棵三阶b-tree,在其中查找关键字100：

![img](/images/B-Tree查找操作.png)

下面给出查找代码：

假设根结点为root，查找关键字为k

```c
BTNode *search_btree(BTree root, key k, int *pos) {
    int i;
    BTNode *p = root;
    while (p != NULL) { // 根据不为空时进行查找
        i = p->key_num;
        while(k > p->key[i]) // 从key_num向前查找第1个小于等于k的关键字
            i--;
		if (k == p->key[i] && i > 0) // 找到了k
            pos = i; return p;
        p = p->ptr[i];   // 向下一层查找
    }
    return NULL;
}

```

## B-Tree应用在数据库的存储

介绍完了b-tree结构的基本操作，我们将之前的数据采用b-tree结构进行存储，如下图所示

![img](/images/B-Tree存储数据.png)

# Mysql中的索引

学习完上面知识点后，我们开始学习mysql中的索引, mysql中的索引不是由mysql服务器实现，而是由存储引擎实现，因此不同的存储引擎采用不同的数据结构。

## B-Tree索引

通过上面对b-tree数据结构的学习，我们对b-tree已经有了一个较为深入的认识，接下来学习b-tree在mysql中的一些特点。

假设我们有一个`people`表,表结构如下

```sql
CREATE TABLE `people` (
`last_name`  varchar(50) NOT NULL ,
`first_name`  varchar(50) NOT NULL ,
`dob`  date NOT NULL ,
INDEX `last_name_first_name_dob_idx` (`last_name`, `first_name`, `dob`) USING BTREE 
)ENGINE=InnoDB;
```

我们新建了一个多列索引，索引类型时b-tree, mysql对多个值排序的依据时创建表时定义的索引顺序。

b-tree索引适用于全键值、键值范围或键前缀查找。前缀查找只适用于做前缀，根据b-tree数据结构的定义，这不难理解。

那么b-tree索引对如下类型的查询有效

**全值匹配**

全值匹配是指和索引中的所有列进行匹配，例如查找姓：Allen 名: Cuba 出生日期：1960-01-01的人

```sql
select first_name, last_name, dob  from people where last_name = "Allen" and first_name = "Cuba" and dob = "1960-01-01"
```

**匹配最左前缀**

根据索引列创建的顺序，只使用第一列，例如查找`last_name = "Allen"`

```sql
select first_name,last_name,dob from people where last_name = "Allen"
```

**匹配列前缀**

只匹配某一列的开头部分，例如查找所有以A开头的姓的人，这也只使用了索引第一列

```sql
select first_name,last_name,dob from people where last_name like 'A%';
```

**匹配范围值**

例如查找下姓在Allen和Barrymore之间的人，这也只使用了索引第一列

```sql
select first_name,last_name,dob from people where last_name between 'Allen' and 'Barrymore'
```

**精确匹配某一列并范围匹配另一列**

例如查找所有姓为Allen，并且名字是字母K开头的，这里first_name全匹配，last_name范围匹配

```sql
select first_name,last_name,dob from people where last_name = 'Allen' and first_name like 'K%';
```

索引不生效的限制：

- 不是按照索引最左列查找。例如下面的查询无法使用到索引

  ```sql
  select first_name, last_name, dob from people where first_name = 'Allen'
  ```

- 不能跳过索引中的列。例如下面的查询, 如果不指定first_name，则索引只能使用第一列**last_name**

  ```sql
  select first_name, last_name, dob from people where last_name = 'Cuba' and dob ='1960-01-01'
  ```

- 查询中有某个某个列的范围查询，那么右边所有列都无法使用索引优化查找。例如下面的查询

  ```sql
  select first_name, last_name, dob from people where last_name = 'Allen' and first_name like 'C%' and dob = '1960-01-01'
  ```

## Hash索引

hash索引使用hash table结构，存储引擎对索引计算一个hash code, 不同键值计算的hash code不同，但也有较小几率冲突。

hash索引非常适合查找表的需求。

hash索引的特点

- hash索引只保存hash code和指针，不保存字段值，所以不能使用索引覆盖。
- hash索引数据并不是有序的，所以不能用来排序
- hash所以不支持部分列匹配查找，只支持所有全值匹配，因为要计算hash code
- hash索引只支持等值比较，不支持范围查询
- hash冲突较多的情况下，一些索引维护工作的代价较高。

## B-Tree索引上模拟使用hash索引

假设如下一张表，存储访问过的url, 对其中的url字段加了b-tree索引，每次检索一条url时，可以这样 `select * from visit_urls where url = "https://www.google.com";` 这样索引可以生效，但有如下几个问题：

- url比较长，当数据很多的时候，会占用大量的空间
- 计算用到了索引，在对索引进行比较时，仍然会耗费大量的时间

针对这个问题，我们可以将url进行hash，然后对hash的列建立索引。

```sql
CREATE TABLE `visit_urls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `url` varchar(255) NOT NULL DEFAULT '',
  `url_crc32` unsigned int(10) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `visit_urls_url_crc32_idx` (`url_crc32`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

接着我们创建一个触发器, 触发器的主要作用是当插入和更新一个url时，会生成hash值，hash函数采用crc32

```sql
delimiter //
create trigger visit_urls_url_crc32_ins BEFORE INSERT ON visit_urls for each row
begin
set NEW.url_crc32 = crc32(NEW.url);
end;
//

create trigger visit_urls_url_crc32_upd BEFORE UPDATE ON visit_urls for each row
begin
set NEW.url_crc32 = crc32(NEW.url);
end;
//

delimiter ;
```

接着我们创建一个存储过程来插入一些数据

```sql
delimiter //
create procedure insert_visit_urls_procedure(IN n int)
begin 

declare i int default 0;

while i<n
do 
set @protocol = IF(floor(rand() * 2) = 1, "http://", "https://");
set @host = CONCAT("www.", substring(MD5(RAND()),5,20), ".com");

insert into visit_urls (url) values(CONCAT(@protocol, @host));
set i = i + 1;

end while;

end;
//
delimiter ;

call insert_visit_urls_procedure(100000);
```

但是使用MD5()和SHA1() hash生成的字符串也非常长，比较时也会慢，一个办法是MD5()函数返回值的一部分作为自定义hash函数

```sql
SELECT CONV(RIGHT(MD5('http://www.google.com'), 16), 16), 10) AS HASH64
```