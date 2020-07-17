---
title: "分布式算法-Paxos了解"
date: "2019-05-10"
categories: ["分布式系统"]
tags: ["分布式算法","paxos"]
---

Paxos是莱利斯·兰伯特(Leslie Lamport)在1990年提出的一种基于消息传递并且有很高容错能力的一个一致性算法。

## 拜占庭问题

1982年，Lamport和另外的两人发表了论文，提出了一种计算机容错理论。在论述过程中设想了一个场景：

拜占庭帝国有很多将军，不同的军队之间必须制定一个统一的行动计划，从而做出进攻或撤退的决定，同时各个将军在地址位置上是分隔开的，只能依靠军队的通讯员通信。然而，在所有的通讯员中都有可能存在叛徒，这些叛徒可以任意篡改消息，从而达到欺骗将军的目的。

在分布式系统中，试图在一个不可靠的环境下来达到一致性是不可能的，因此对分布式一致性问题的讨论中，都假设消息是可靠的。事实上，大多数系统都是部署在局域网中，消息被篡改是很罕见的。另外如果因为硬件和网络原因造成的消息丢失，网络传输协议都会用检验算法来验证消息的完整性。因此在实际的事件中，一般假设 `拜占庭问题` 不存在。

## Paxos算法的特点

### 一致性

假设有一个变量v，分布在N个进程中，每个进程都尝试修改v值，它们尝试修改的v的值可能各不相同，比如进程P1修改 v = a,
进程P2修改v = b. 但最终，所有存活的节点都应该对v的值达成一致。在某个时刻达成一致并不等价于这个时刻所有的节点都达成一致，进程可能会挂掉，而挂掉的进程做不了任何事情。

总结一下就是：

- 在N个节点的修改请求中，只有一个v值被选定
- 如果没有节点需要修改v的值，那么就不会有v值被选定
- 当一个v值达成一致后，其他进程也可以获取到v的值

### 安全性

一旦v对某个值达成一致，v就不能对另外的值达成一致

### 活性

就v而言，总能对某个值达成一致。

### 进程平等性

Paxos要求进程之间是平等的关系，没有特殊的进程。

试想，如果存在一个特殊的进程，Paxos依赖该进程，如果该进程挂掉，会影响整个算法。而在分布式环境中，不能保证单个进程必然存活。

## Paxos算法推导

### Paxos的数学原理

假设多个进程组成的集合称为法定集合，法定集合性质：两个法定集合必然存在非空交集。

也就是说两个进程集合之间必然存在至少一个公共进程。

设ABCDEF为全集，集合Q1包含进程ABC, 集合Q2包含进程CDEF，那么Q1和Q2的交集不为空，C就是Q1和Q2的公共进程。

### 场景1

假设存在这样一种场景，有三个进程P1、P2、和P3，其中有一个变量v

- P1进程尝试将v的值修改为 v = a
- P2进程尝试将v的值修改为 v = b

那么根据法定集合性质，我们假设P3为公共进程，如果让v就某个值达成一致，那么需要多数进程达成一致。而P3就是关键的进程

如果P1通过消息通知P3让 v = a， P2也发送消息通知P3 让 v = b, 如果P3都满足他们的请求，那么v就会出现两次定义为不同的值，这样就出现了不一致性，因此P3必须拒绝掉一个请求。

假设一个简单的拒绝策略就是P3总是接受第一个消息，拒绝之后的消息, v的值只改写一次。按照这个策略，如果P3也尝试修改自己的值，P3将 v = c, 那么存在P1、P2、P3都修改v的值，按照策略，v的值只改写一次，首先P1将v = a, P2将v = b, P3将v = c（自己给自己发消息）,那么各自都会拒绝掉后来的消息，那么就用法不会出现两个进程v的值一致的情况，v的值永远不能被决定。这样的算法就不满足活性。

因此由场景1得到一个结论：进程必须能够多次改写v的值。同时进程在收到第一个消息时，进程时不能拒绝的。

### 拒绝策略

由场景1知道，不能只接收一个消息而拒绝后续的消息。在修改拒绝策略前，需要有一个依据，这个依据可以区分多个消息。假设引入一个id (实时上在讨论Paxos之前会假设已经实现了类似的生成器)，这个id是递增的。

根据id可以区分不同的消息，因此让P1.id > P2.id > P3.id, 现在的拒绝策略是，进程能接收多个消息，但进程只接受最大/最小的那个消息。这里不妨设定为进程只接受最大的那个消息。

根据这个拒绝策略继续看之前的问题:
P3先收到P1的消息，由于P1是P3第一个收到的消息，P3接受请求，将v = a; 同时为了能对后续的消息做判断，P3记录消息id, 紧接着P2消息到达，由于 P2.id < P3.id = P1.id, 因此拒绝P2的消息。记这个场景为1-2。

P3先收到P2的消息，后续P1的消息到达，由于P1.id > P3.id = P2.id, 因此又接受了P1。这样不满足一致性。记这个场景为1-3.

在继续深入之前，先统一一些称谓：
将进程P发送尝试修改另一个进程变量的v的值的消息称之为**Proposal**, Proposal的id记为**Proposal.id**, 提案会附带一个值，如果一个进程接受一个提案，则修改自身的v值为提案的值。如果一个提案被大多数进程接受，则称**提案通过**。

进程P接受的提案id记为Proposal.a_id

对于如何选定Proposal.a_id, 规定 Proposal.a_id = MAX(Proposal.id, Proposal.a_id) 也就是说，进程在接受到一个Proposal时，如果提案的id比之前已经接受过的a_id要大，就更新Proposal.a_id 为当前提议的id。

基于上面的讨论，进程应该存在两个功能：

1. 进程尝试另v等于某个值，我们将这个尝试称为提案，但在改变v之前，需要向进程集合广播提案。
2. 进程被动收到来自其他进程的提案，判断是否接受。

因此可以将进程分为两个角色：

1. 提议者-Proposer: 负责功能1
2. 接收者-Acceptor: 负责功能2

### 场景1-3的问题

对于场景1-2，现存的拒绝策略可以应付，但对于场景1-3，我们还需要改变拒绝策略。尝试从下面三个方向入手：

1. P3能够拒绝掉P2
2. P3能够拒绝掉P1
3. 限制P1的值，让P1的值和P2一致
4. P3能够拒绝掉P2
   P3能拒绝掉P2需要给出足够充分的理由，在这里只能是P3事先知道P1的Proposal.id，从而拒绝掉P2。问题是P3不会像P1主动询问，因为P3不知道P1和P2谁的id更大，同样的P2和P1也互相不知道谁大。如果P3能够拒绝掉P2，我们需要让P3在接收到P2前事先接收了P1，但这样的情况与场景1-3先接受P2存在矛盾。
   于是做出这样的设想：**在提议前，进程主动像Acceptor发送预提案，预提案附带提案的v和id，Acceptor接收到预提案，更新 Acceptor.a_id = MAX(a_id, Proposal.id)**

在基于此设想下，引出了两个场景：

1. P3先接收到P1的预提案，之后接收到P2的提案，这种情况下，可以满足一致性。
2. P3先接收到P2的提案，更新P3.a_id = MAX(P3.a_id, P2.id) P3.v = P2.v, 之后接收到P1的预提案，由于P1.id > P2.id, 所以P3.a_id = MAX(P3.a_id = P2.id, P1.ID) 又另P3.v = P1.v，不满足一致性，记这个场景为1-3-2.

1. P3能够拒绝掉P1
   P3似乎没有任何理由拒绝掉P1，这个方向似乎不是一个好的方向。
2. 限制P1的值
   限制P1的值，让P1的值和P2一致。这就意味着P1在正式提出提案之前需要有途径知道P2的值，在分布式环境下，消息是唯一的通信手段，P1要想获知P2的值，可以被动等待，也可以主动询问。主动询问显然更好，被动等待可能导致活性问题。

到目前为止，协议的流程分为两个阶段：预提案阶段和提案阶段。两种消息：预提案和提案。两种角色：接收者和提案者。

流程如下：

1. 阶段1：Proposer向Acceptor广播预提案，附带接下来的提案id, Acceptor接收到提案，更新 a_id = MAX(a_id, Proposal.id)
2. 阶段2：Proposer向Acceptor广播提案，和之前预提案共享id,Acceptor接收到提案，如果提案的Proposal.id > Acceptor.a_id， 更新a_id = MAX(a_id, Proposal.id)

### N个进程的推广

在解决场景1-3-2之前，为了协议更通用，将其推广到N个进程，N个进程中，有两个进程Pi、Pj, Pi尝试另v = a, Pj尝试另v = b, Pi的预提案记为PreProposal-i, Pj的预提案记为PrePosal-j.

之前的拒绝策略存在一个关键进程P3，事实上在N个进程中，Pi的提案能被通过，肯定存在一个法定集合Qi，Q中的所有进程都通过了Pi的提案，同样也存在一个Qj,由于法定集合的性质，Qi和Qj必然存在一个公共进程Pk.Pk即相当于场景1中的P3，只要Pk能够拒绝Proposal-i和Proposal-j中的一个，协议依旧是安全的。

### 推导选值策略

由于在1-3-2的场景中，拒绝策略会失效，所以只能令 **ProPosal-i.v = Proposal-j.v**.

由之前方向3做出的推断，Pi需要主动询问进程集合，来得知Proposal-j.v = b的事实。显然Pi并不知道Proposal-j由哪个进程提出，也不知道Qi和Qj的公共节点是谁，因此Pi只能广播它的查询，由于允许进程存在失败，因此Pi能收到来自大多数进程的回复，而这其中可能不包括Pj. 记这些回复的进程为Qi-2. 假设Qi-2 = Qi

由于Pk属于Q-i和Q-j的交集，基于场景1-3-2, **Pk已经接受了Pj的提案,所以Pk既收到了Pi的查询，又接受了提案Proposal-j**

由于之前引入了预提案，显然可以在预提案时附带查询的意图，**Pk作为接收者回复它记录的提案**

在1-3-2场景中 **Pj的提案Proposal-j是先于Pi的预提案PreProposal-i先到达， 所以Pk已经记录了Proposal-j.v = b**。

#### 公共进程如何回复预提案

在N个进程中，除了Pi和Pj外还会存在很多预提案和提案，所以Pk收到PreProposal-i时Pk可能已经接受过多个提案，并非只有Pj. 那么Pk应该回复给Pi自己接受过的提案中的哪个提案呢？或者都回复？**都回复是个效率很低但是稳妥，可以保证Pk不会遗漏Proposal-j**， 所以目前假设都回复。

#### 预提案进程如何选择回复提案

Pi收到了多个Proposal作为一个Acceptor组成的法定集合Q-i对PreProposal-i的回复，记这些Proposal组成的集合记坐K-i，那么它应当选择K-i中哪个一个提案的值作为它接下来的提案Proposal-i的v值？记最终选择的这个提案为Proposal-m。

#### 选值策略

为了应对1-3-2的问题，只要保证Pi选择的回复提案Proposal-m.v = Pj.Proposal.v即可。从对立的角度出发，K-i中很可能存在这样一个
**提案Pf, Pf.Proposal.v != Pj.Proposal.v**，只要避免选择Pf这样的提案即可。

所以设想一个策略为CL，**CL满足需求：使得选择出的提案Proposal-m满足Proposal-m.v= Proposal-j.v。**

**Proposal-f能够被提出，代表了一个法定集合Qf, Qf中每个进程都接受了PreProposal-f, Pf提出了PreProposal-f和Proposal-f**, 那么Qf和Qj必然存在一个公共节点Ps, **Ps既接受了Qj又接受了PreProposal-f**

那么对于Ps,存在以下两个情形：

1. Ps先接受了PreProposal-f
2. Ps先接受了Pj

在论述情形之前，假设**PreProposal-f.id > Pj.id**.

对于情形1：

Ps接受到了PreProposal-f 更新 Ps.a_id = PreProposal-f.id。

同时之前的a_id的更新策略又使得Ps.a_id是递增的，于是导致收到Proposal-j时,Proposal-j.id < Ps.a_id,被拒绝，而这于Ps的定义 **同时接受了PreProposal-f和Proposal-j矛盾**。

对于情形2：

Ps接受了Pj, 更新Ps.a_id = Pj.Proposal.id < PreProposal-f.id。

由于设想了CL的存在，所以Ps会回复给Pf自己接受过的提案。**当Pf收到所有Qf对PreProposal-f的回复后，将令Proposal-f.v=Proposal-j.v**， 而这与 **PreProposal-f.v != Pj.Proposal.v**矛盾。

显然假设 PreProposal-f.id > Pj.id是不成立的。所以 **PreProposal-f.id < Pj.Proposal.id 即Pf.Proposal.id < Pj.Proposal.id**

于是得到结论：
如果选值策略存在，并且提案Pj.Proposal会被通过，任意一个Proposal.id更大的提案。对于它得到的回复集合中的Pf.Proposal, 只要Pf.Proposal.v != Pj.Proposal.v, 则 **Pf.Proposal.id < Pj.Proposal.id**。

在回到之前 **预提案进程如何选择回复提案** 这里，既然得到K-i中的所有v值 != Pj.Proposal.v的提案id都要小于Pj.Proposal.id, 那么
**所有Ki(Proposal.id) > Pj.Proposal.id的提案，提案的值都等于Pj.Proposal.v**， 只要选择K-i集合中最大的提案，就能保证Proposal.v = ProPosal-j.v。于是得到了选值策略的具体形式。

#### 基于选值策略的协议流程

1. 阶段1：Proposer广播PreProposal，附带接下来Proposal.id, Acceptor收到PreProposal后，更新Acceptor.a_id = MAX(a_id, PreProposal.id), 如果PreProposal.id > Acceptor.a_id, 那么Acceptor回复给预提案进程接受过的所有提案。
2. 阶段2：Proposer等待直到收到大多数Acceptor对PreProposal的回复，从所有回复组成的集合K中选择最大的Proposal.v，作为本次Proposal.v。如果K是空集，那么可以给提案任意赋值。 向Acceptor广播Proposal，和PreProposal共享同一个id. Acceptor如果收到的提案的id >= a_id，那么接受这个提案，更新Acceptor.a_id = MAX(Proposal.id,a_id)。

## 最终的Paxos

阶段1中Acceptor的行为，它要回复所有的它接受过的提案，从实践的角度，不论是在本地保存所有它接受过的提案还是通过网络将它们传输给提议者，开销都太大且不可控。

阶段2中，提议者的选值策略，它只是选择了收到的多数集接受者回复的提案中Proposal.id最大的那一个，因此Acceptor实际上只要回复它接受过的最大的Proposal即可，因为其它提案根本不可能会被选值策略选中。因此最终的协议如下，它就是Paxos:

阶段1(预提案阶段): Proposer向Acceptor广播预提案，附带接下来提案Proposal的id. Acceptor收到预提案后更新Acceptor.a_id = MAX(proposal_id,a_proposal_id) > a_id，Acceptor回复记录的接受过id最大的Proposal。

阶段2(提案阶段): Proposer等待直到收到大多数接受者对预提案的回复，从所有回复的提案组成的法定数目的提案集合K中挑选id最大的提案，以该提案的值作为本次提案的值。如果K是空集，那么可以给提案任意赋值。然后把该提案广播给接受者们，提案和预提案共享同一个id。 Acceptor如果收到的提案的proposal_id >= a.proposal_id，那么接受这个提案，更新Acceptor.a_id = max(proposal_id,a_proposal_id)，更新记录的提案。

参考：

<<从Paxos到Zookeeper>>

知乎关于Paxos的回答(https://www.zhihu.com/collection/270497231)