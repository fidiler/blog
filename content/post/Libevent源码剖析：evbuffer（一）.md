---
title: Libevent源码剖析：evbuffer（一）
date: "2020-04-27"
categories: ["network programming"]
tags: ["libevent"]
---



## 数据结构

evbuffer的基本原理是使用单向链表存储整个buffer的数据. 链表的每个节点看作一个chunk. 

## evbuffer_chain
evbuffer chain是一个单向链表, 存储着实际的data.

```c
struct evbuffer_chain {
	/** 链向下一个节点 */
	struct evbuffer_chain *next;
	/** 记录分配给buffer的内存长度 */
	size_t buffer_len;

	/** TODO */
	ev_misalign_t misalign;

	/** TDO */
	size_t off;

	/** Set if special handling is required for this chain */
	unsigned flags;
#define EVBUFFER_FILESEGMENT	0x0001  /**< A chain used for a file segment */
#define EVBUFFER_SENDFILE	0x0002	/**< a chain used with sendfile */
#define EVBUFFER_REFERENCE	0x0004	/**< a chain with a mem reference */
#define EVBUFFER_IMMUTABLE	0x0008	/**< read-only chain */
	/** a chain that mustn't be reallocated or freed, or have its contents
	 * memmoved, until the chain is un-pinned. */
#define EVBUFFER_MEM_PINNED_R	0x0010
#define EVBUFFER_MEM_PINNED_W	0x0020
#define EVBUFFER_MEM_PINNED_ANY (EVBUFFER_MEM_PINNED_R|EVBUFFER_MEM_PINNED_W)
	/** a chain that should be freed, but can't be freed until it is
	 * un-pinned. */
#define EVBUFFER_DANGLING	0x0040
	/** a chain that is a referenced copy of another chain */
#define EVBUFFER_MULTICAST	0x0080

	/** number of references to this chain */
	int refcnt;

	/** Usually points to the read-write memory belonging to this
	 * buffer allocated as part of the evbuffer_chain allocation.
	 * For mmap, this can be a read-only buffer and
	 * EVBUFFER_IMMUTABLE will be set in flags.  For sendfile, it
	 * may point to NULL.
	 */
	unsigned char *buffer;
};
```

## evbuffer
```c
struct evbuffer {
	/** 链表第一个元素指针 */
	struct evbuffer_chain *first;
	/** 链表最后一个元素指针*/
	struct evbuffer_chain *last;
        /** 追踪指向链表最后一个元素的指针的指针 */
	struct evbuffer_chain **last_with_datap;
	/** 记录正个链表存储的chunk的大小*/
	size_t total_len;
	/** 最大读取的字节数 */
	size_t max_read;

	/** Number of bytes we have added to the buffer since we last tried to
	 * invoke callbacks. */
	size_t n_add_for_cb;
	/** Number of bytes we have removed from the buffer since we last
	 * tried to invoke callbacks. */
	size_t n_del_for_cb;

#ifndef EVENT__DISABLE_THREAD_SUPPORT
	/** A lock used to mediate access to this buffer. */
	void *lock;
#endif
	/** True iff we should free the lock field when we free this
	 * evbuffer. */
	unsigned own_lock : 1;
	/** 标记buffer不可删除*/
	unsigned freeze_start : 1;
	/** 标记buffer不可添加*/
	unsigned freeze_end : 1;
	/** True iff this evbuffer's callbacks are not invoked immediately
	 * upon a change in the buffer, but instead are deferred to be invoked
	 * from the event_base's loop.	Useful for preventing enormous stack
	 * overflows when we have mutually recursive callbacks, and for
	 * serializing callbacks in a single thread. */
	unsigned deferred_cbs : 1;
#ifdef _WIN32
	/** True iff this buffer is set up for overlapped IO. */
	unsigned is_overlapped : 1;
#endif
	/** Zero or more EVBUFFER_FLAG_* bits */
	ev_uint32_t flags;

	/** Used to implement deferred callbacks. */
	struct event_base *cb_queue;

	/** A reference count on this evbuffer.	 When the reference count
	 * reaches 0, the buffer is destroyed.	Manipulated with
	 * evbuffer_incref and evbuffer_decref_and_unlock and
	 * evbuffer_free. */
	int refcnt;

	/** A struct event_callback handle to make all of this buffer's callbacks
	 * invoked from the event loop. */
	struct event_callback deferred;

	/** A doubly-linked-list of callback functions */
	LIST_HEAD(evbuffer_cb_queue, evbuffer_cb_entry) callbacks;

	/** The parent bufferevent object this evbuffer belongs to.
	 * NULL if the evbuffer stands alone. */
	struct bufferevent *parent;
};
```
evbuffer是evbuffer_chain的一层封装, 包含
- 记录首尾元素的指针: fist 和last
上面两个`struct`是整个evbuffer实现用到的数据结构, 通过操作这些数据结构, 对外封装了一系列的接口, 接下来就来一一剖析这些接口的实现

## 初始化: evbuffer_new
初始化一个evbuffer很简单, 只需要调用`evbuffer_new()`. 
```c
struct evbuffer *
evbuffer_new(void)
{
	struct evbuffer *buffer;

	buffer = mm_calloc(1, sizeof(struct evbuffer));
	if (buffer == NULL)
		return (NULL);

	LIST_INIT(&buffer->callbacks);
	buffer->refcnt = 1;
	buffer->last_with_datap = &buffer->first;
	buffer->max_read = EVBUFFER_MAX_READ_DEFAULT;

	return (buffer);
}
```
首先调用内存分配macro分配了一个evbuffer的结构. 
LIST_INIT初始化了callback 函数调用列表 (双端队列实现, 后面细说). 
接着设置引用计数refcnt为1, 设置last_with_datap等于buffer的首元素, first是一个null pointer, 所以在没有数据的情况下, last_with_datap指向的数据也为null, 但last_with_datap不为null, 是指向fist的一个地址. 
因此这个单向链表是没有哑节点的. max_read设置为EVBUFFER_MAX_READ_DEFAULT, 这个macro在当前版本的值是4096.

## 添加元素: evbuffer_add
evbuffer_add向buffer追加元素, 追加的数据大小有限制, 代码中会体现, 其接口如下
`int evbuffer_add(struct evbuffer *buf, const void *data_in, size_t datlen) `
data_in 是要追加到buffer的数据, datlen指示它的长度, 该接口调用会进行**内存拷贝**.

在完整的浏览evbuffer_add的具体实现之前, 需要先浏览组成evbuffer_add接口的其他几个接口

### 创建链表节点: evbuffer_chain_new
```c
static struct evbuffer_chain *
evbuffer_chain_new(size_t size)
{
	struct evbuffer_chain *chain;
	size_t to_alloc;

    /** 防止buffer_len溢出*/
	if (size > EVBUFFER_CHAIN_MAX - EVBUFFER_CHAIN_SIZE)
		return (NULL);
    /** 除了要为data分配内存之外, 还要额外的为节点分配内存*/
	size += EVBUFFER_CHAIN_SIZE;

	/** 计算要分配的内存大小
    * 如果小于EVBUFFER_CHAIN_MAX/2, 则从MIN_BUFFER_SIZE起开始分配, 
    * 直到to_alloc >= size的时候, 由于每次to_alloc <<=1, 
    * 计算后的to_alloc应该是size的二倍左右的大小
    * 否则 to_alloc = size
    */
	if (size < EVBUFFER_CHAIN_MAX / 2) {
		to_alloc = MIN_BUFFER_SIZE;
		while (to_alloc < size) {
			to_alloc <<= 1;
		}
	} else {
		to_alloc = size;
	}

	/** 进行内存分配, 分配了evbuffer_chain结构本身所用内存+datlen所需内存(有可能比它大) */
	if ((chain = mm_malloc(to_alloc)) == NULL)
		return (NULL);
    /** 初始化*/
	memset(chain, 0, EVBUFFER_CHAIN_SIZE);
    /** buffer实际的内存大小应该是减去evbuffer_chain结构本身的*/
	chain->buffer_len = to_alloc - EVBUFFER_CHAIN_SIZE;

	/** 这里会为buffer附加一些额外的内存, 然后得到一个与chain不同的地址, 这样就可以用于mmap这类系统调*/
	chain->buffer = EVBUFFER_CHAIN_EXTRA(unsigned char, chain);
    /** 引用计数值*/
	chain->refcnt = 1;

	return (chain);
}
```
分配链表一个节点时, 将**chain本身所需内存和size长度的buffer所需的内存一次性分配**.
计算需要分配的大小也很简单：如果小于`EVBUFFER_CHAIN_MAX / 2`, 以`MIN_BUFFER_SIZE`为开始进行分配，分配完成后，会得到一个 (size + EVBUFFER_CHAIN_SIZE) * 2 的大小。否则就分配size + chain个大小.
在分配buffer时, 进行了一个附加操作, 这个macro定义如下

```c
#define EVBUFFER_CHAIN_EXTRA(t, c) (t *)((struct evbuffer_chain *)(c) + 1)
```
expand macro后能够得到 `(unsigned char *)((struct evbuffer_chain *)(chain) + 1)`
**作用是能够得到一个起始的内存地址与chain不同的地址, 被诸如mmap之类的系统调用使用时，会映射到一个不同的地址，使用这个地址的时候，不会影响chain本身**

### 插入节点到链表：evbuffer_chain_insert

```c
/* Add a single chain 'chain' to the end of 'buf', freeing trailing empty
 * chains as necessary.  Requires lock.  Does not schedule callbacks.
 */
static void
evbuffer_chain_insert(struct evbuffer *buf,
    struct evbuffer_chain *chain)
{
	ASSERT_EVBUFFER_LOCKED(buf);
	if (*buf->last_with_datap == NULL) {
		/* There are no chains data on the buffer at all. */
		EVUTIL_ASSERT(buf->last_with_datap == &buf->first);
		EVUTIL_ASSERT(buf->first == NULL);
		buf->first = buf->last = chain;
	} else {
		struct evbuffer_chain **chp;
		chp = evbuffer_free_trailing_empty_chains(buf);
		*chp = chain;
		if (chain->off)
			buf->last_with_datap = chp;
		buf->last = chain;
	}
	buf->total_len += chain->off;
}
```

插入一个chain到链表中分两种情况讨论：

1. 链表为空：evbuffer指向的last_with_datap为NULL

   这种情况下，插入的时候assert了一下确保要插入的evbuffer->last_with_datap指向的位置是first节点，同事然后让指针evbuffer->fist 和 evbuffer->last等于该chain的指针即可

2. 链表不为空

   这种情况，会调用`evbuffer_free_trailing_empty_chains` 接口找到一个合适的插入位置

### evbuffer_free_trailing_empty_chains 

```c
static struct evbuffer_chain **
evbuffer_free_trailing_empty_chains(struct evbuffer *buf)
{
    /** 从last_with_datap位置开始查找*/
	struct evbuffer_chain **ch = buf->last_with_datap;
	
    /** 找到一个可用的chian节点 */
	while ((*ch) && ((*ch)->off != 0 || CHAIN_PINNED(*ch)))
		ch = &(*ch)->next;
    /** ch节点不为NULL */
	if (*ch) {
        /** assert ch节点以及后续节点都是empty*/
		EVUTIL_ASSERT(evbuffer_chains_all_empty(*ch));
		/** 释放ch节点以及后续节点的内存 */
        evbuffer_free_all_chains(*ch);
		*ch = NULL;
	}
    /** ch为NULL, 是一个可插入的位置, 直接返回*/
	return ch;
}
```

`evbuffer_free_trailing_empty_chains`算法从buf->last_with_datap位置开始，查找链表当中可插入的位置：

`buf->last_with_datap`在链表首次插入的情况下，`*ch`是为NULL的，因此直接返回*ch

不是首次插入的情况下，从ch开始遍历整个链表，注意遍历的时候增加了附加条件，`(*ch)->off != 0` 说明节点正在被使用，`CHAIN_PINNED(*ch)` 表示当前节点是pinned状态，**pinned的节点不可以被free或move**.

迭代过程组合`(*ch)->off != 0 || CHAIN_PINNED(*ch)`这两个逻辑表示：**找到一个节点，节点off=0或者un-pinned**

如果找到了这样的节点（`*ch != NULL`），说明节点没有被使用了，同时后续的节点也应该是没有被使用的，释放从这个节点开始到链表末尾的所有内存。**这个过程可以看作是对空闲链表的内存管理，减少memory leak**。

如果不存在这样的节点（**正常的add没有remove的操作下*ch一直取得是NULL**），则找到了插入位置。



evbuffer_add具体实现如下
```c
int
evbuffer_add(struct evbuffer *buf, const void *data_in, size_t datlen)
{
	struct evbuffer_chain *chain, *tmp;
	const unsigned char *data = data_in;
	size_t remain, to_alloc;
	int result = -1;

	EVBUFFER_LOCK(buf);

    /** 如果标记了freeze_end = 1, 不会写数据 */
	if (buf->freeze_end) {
		goto done;
	}
	/** 防止total_len 类型溢出, 溢出不会在添加数据*/
	if (datlen > EV_SIZE_MAX - buf->total_len) {
		goto done;
	}

    /** 查找chain插入的开始节点*/
	if (*buf->last_with_datap == NULL) {
		chain = buf->last;
	} else {
		chain = *buf->last_with_datap;
	}

    /** 第一次add的时候,chain肯定是为null的, 因此会根据 datlen分配内存*/
	if (chain == NULL) {
        /** 创建链表节点 */
		chain = evbuffer_chain_new(datlen);
		if (!chain)
			goto done;
        /** 插入节点 */
		evbuffer_chain_insert(buf, chain);
	}
	
    /** 判断chain是否为read-only */
	if ((chain->flags & EVBUFFER_IMMUTABLE) == 0) {
		/* Always true for mutable buffers */
		EVUTIL_ASSERT(chain->misalign >= 0 &&
		    (ev_uint64_t)chain->misalign <= EVBUFFER_CHAIN_MAX);
        
        /** 计算chain的buffer剩余多少字节可用 */
		remain = chain->buffer_len - (size_t)chain->misalign - chain->off;
        
        /** chain的buffer剩余的字节大于申请的字节 */
		if (remain >= datlen) {
			/* there's enough space to hold all the data in the
			 * current last chain */
			memcpy(chain->buffer + chain->misalign + chain->off,
			    data, datlen);
            /** 更新当前buffer使用的字节*/
			chain->off += datlen;
            /** 记录buf总共有多少字节*/
			buf->total_len += datlen;
            /** 这个filed会传给cb, 和total_len一致 */
			buf->n_add_for_cb += datlen;
			goto out;
		} else if (!CHAIN_PINNED(chain) &&
		    evbuffer_chain_should_realign(chain, datlen)) {
			/* we can fit the data into the misalignment */
			evbuffer_chain_align(chain);

			memcpy(chain->buffer + chain->off, data, datlen);
			chain->off += datlen;
			buf->total_len += datlen;
			buf->n_add_for_cb += datlen;
			goto out;
		}
	} else {
		/* we cannot write any data to the last chain */
		remain = 0;
	}

	/* we need to add another chain */
    /* to_alloc表示当前chain中buffer的大小 */
	to_alloc = chain->buffer_len;
    /* 调整to_alloc的大小*/
	if (to_alloc <= EVBUFFER_CHAIN_MAX_AUTO_SIZE/2)
		to_alloc <<= 1;
    /* 调整后还不满足需要的大小,则将to_alloc设置为datlen */
	if (datlen > to_alloc)
		to_alloc = datlen;
    /* 分配一个新的chain */
	tmp = evbuffer_chain_new(to_alloc);
	if (tmp == NULL)
		goto done;

    /* 如果chain的buffer还有剩余可用的空间，先将数据复制到剩余可用的空间 */
	if (remain) {
		memcpy(chain->buffer + chain->misalign + chain->off,
		    data, remain);
		chain->off += remain;
		buf->total_len += remain;
		buf->n_add_for_cb += remain;
	}
	
    /* 移动data的指针 */
	data += remain;
    /* 拷贝完remain之后，计算还剩余的data还需要多少字节，然后更新datlen */
	datlen -= remain;

    /* 将剩余的字节拷贝到tmp中 */ 
	memcpy(tmp->buffer, data, datlen);
    /* 将tmp使用的字节off设置为datlen(减去remain的) */
	tmp->off = datlen;
    /* 将tmp插入到链表 */
	evbuffer_chain_insert(buf, tmp);
	buf->n_add_for_cb += datlen;

out:
	evbuffer_invoke_callbacks_(buf);
	result = 0;
done:
	EVBUFFER_UNLOCK(buf);
	return result;
}
```