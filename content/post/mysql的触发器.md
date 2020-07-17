---
title: "认识mysql触发器"
date: "2017-03-09"
categories: ["数据库"]
tags: ["mysql"]
---

在学习之前说一下，关于<<Mysql必知必会>>这本书描述的触发器相关代码全部是**错误**的

# 触发器

触发器是当数据库产生某个事件发生时自动执行的语句，也就是说当以下语句执行时，触发器可以响应：

- DELETE
- INSERT
- UPDATE

## 创建触发器

创建触发器需要以下几个信息：

- 触发器的名称，需要注意是唯一的
- 触发器何时执行（BEFORE/AFTER）
- 触发器应该响应的事件(DELETE/INSERT/UPDATE)
- 触发器关联的表

下面我们创建一个触发器

```sql
CREATE TABLE account (acct_num INT, amount DECIMAL(10,2));
CREATE TRIGGER ins_sum BEFORE INSERT ON account FOR EACH ROW SET @sum = @sum + NEW.account
```



关键字`BEFORE` 指定了触发器何时发生，在这里，触发器将在每次插入前激活，另一个关键字是AFTER

关键字`INSERT`表示触发的的事件，在这里，INSERT操作会激活触发器，可选的操作还有 `DELETE, UPDATE`

`FOR EACH ROW` 后面的语句定义了触发器主体;也就是每次触发器激活时执行的语句，对于受触发事件影响的每一行都会发生一次。

下面我们来触发触发器

```sql
SET @sum = 0;
INSERT INTO account VALUES(137,14.98),(141,1937.50),(97,-100.00);
SELECT @sum AS 'Total amount inserted';
```

+———————–+
| Total amount inserted |
+———————–+
| 1852.48 |
+———————–+

我们还可以为一个事件定义多个触发器

```sql
CREATE TRIGGER ins_transaction BEFORE INSERT ON account
       FOR EACH ROW PRECEDES ins_sum
       SET
       @deposits = @deposits + IF(NEW.amount>0,NEW.amount,0),
       @withdrawals = @withdrawals + IF(NEW.amount<0,-NEW.amount,0);
```



多个触发器可以指定触发的顺序，PRECEDES 指在触发器ins_sum之前触发，同样可选的值还有 F`OLLOWS` 在指定触发器之后触发

不同的事件触发器可引用的值不同：

- 在INSERT事件中，只能使用NEW.col_name, 没有OLD.col_name
- 在DELETE事件中，只能使用OLD.col_name
- 在UPDATE事件中，可以使用OLD.col_name引用更新之前的值，也可以使用NEW.col_name引用更新之后的值

引用OLD.col_name的列是只读的，也就是说可以SELECT引用，但不能修改。

在BEFORE中，还可以 set NEW.col_name = value，但是在AFTER中，SET语句不能使用，因为行已经发生了变化。

在BEFORE中，AUTO_INCREMENT列的NEW值为0，而不是实际插入新行时自动生成的序列号

还可以通过 BEGIN…END来构造触发器，在BEGIN块中，还可以使用像存储过程的语法（例如条件判断和循环），但需要重新定义DELIMITER，以便在触发器中使用;

下面是一个例子

```sql
CREATE TABLE allow_urls (id int not null auto_increment, url varchar(255) not null, url_crc int not null default 0, primary key(id));

delimiter //

CREATE TRIGGER allow_urls_crc_ins BEFORE INSERT ON allow_urls FOR EACH ROW
BEGIN
SET NEW.url_crc = crc32(NEW.url);
END;
// 
delimiter ;
```



当新增访问的url时，将自动计算url的crc32校验和，并设置为新的值

```sql
INSERT INTO allow_urls (url) VALUES("http://www.google.com"), ("https://www.facebook.com");
```



## 删除触发器

```sql
DROP TRIGGER test.ins_sum
```