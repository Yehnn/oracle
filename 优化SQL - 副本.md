# 优化 SQL

## 实验介绍

### 实验内容

SQL 优化实际上就是让 SQL 执行得更快，实现这个目标我们需要减少 I/O 操作，增加系统的吞吐量，也就是单位时间内访问的资源量。

### 实验知识点

+ 追踪 SQL
+ 执行计划
+ SQL 优化
+ SQL 语句格式规范


## 场景

我们对数据库经常会有很多的查询操作，然而在大量的 SQL 语句中，有一些语句处理得格外缓慢，我们需要找出这些运行缓慢，消耗资源特别多的 SQL 语句并分析其执行计划从而进行优化。

> 执行计划：Oracle 数据库执行 SQL 语句，会先生成一个执行计划，然后按照执行计划里的步骤顺序完成。

首先登入实例：

```bash
$ sudo su oracle
$ sqlplus / as sysdba
```

然后构造我们的测试表和测试数据。

### 测试表

```sql
drop table sc;
drop table course;
drop table student;
CREATE TABLE student(
    s_id number,
    s_name VARCHAR2(20) NOT NULL,
    s_sex VARCHAR2(10) DEFAULT 'man',
    s_age NUMBER NOT NULL,
    CONSTRAINT pk_sid PRIMARY KEY (s_id)
);

CREATE TABLE course(
    c_id NUMBER,
    c_name VARCHAR2(20) NOT NULL,
    c_time NUMBER,
    CONSTRAINT pk_cid PRIMARY KEY (c_id), 
    CONSTRAINT uk_cname UNIQUE (c_name)
);

CREATE TABLE sc(
    s_id NUMBER,
    c_id NUMBER,
    grade NUMBER,
    CONSTRAINT pk_scid PRIMARY KEY (s_id, c_id),
    CONSTRAINT fk_sid FOREIGN KEY (s_id) REFERENCES student(s_id),
    CONSTRAINT fk_cid FOREIGN KEY (c_id) REFERENCES course(c_id)
);
```

### 测试数据

如下命令向 course 表插入了 7 条数据，向 student 和 sc 表中插入了十万条随机数据：

```sql
BEGIN
  INSERT INTO course VALUES(1, 'java', 13);
  INSERT INTO course VALUES(2, 'python', 12);
  INSERT INTO course VALUES(3, 'c', 10);
  INSERT INTO course VALUES(4, 'spark', 15);
  INSERT INTO course VALUES(5, 'php', 20);
  INSERT INTO course VALUES(6, 'hadoop', 11);
  INSERT INTO course VALUES(7, 'oracle', 22);
  FOR i IN 1..100000 LOOP
    INSERT INTO /*+ append */ student VALUES(i,'syl'||i,DECODE(TRUNC(DBMS_RANDOM.VALUE(0,2)),0,'man',1,'female'),TRUNC(DBMS_RANDOM.VALUE(12,80)));
    INSERT INTO /*+ append */ sc VALUES(i,TRUNC(DBMS_RANDOM.VALUE(1,8)),TRUNC(DBMS_RANDOM.VALUE(0,101)));
    IF MOD(i,5000)=0 THEN 
           COMMIT; 
    END IF; 
  END LOOP;
END;
/
```

提示：数据量巨大，需要等待一段时间。语句中的 `/*+ append */` 代表采用直接路径插入，使插入更快，每 5000 行提交一次也是为了提高速度。

接下来看看是否都插入成功了：

```sql
SQL> select count(*) from student;

  COUNT(*)
----------
    100000

SQL> select count(*) from course;

  COUNT(*)
----------
	 7

SQL> select count(*) from sc;

  COUNT(*)
----------
    100000
```

我们想找出哪些 SQL 语句需要优化，就得首先追踪 SQL 。

## 追踪 SQL

追踪 SQL 是为了找出那些执行时间缓慢，消耗资源过高的 SQL 语句。可以使用 `SQL TRACE` 工具和 `DBMS_MONITOR` 包。推荐使用 `DBMS_MONITOR` 包，它具有更高的灵活性。我们下面主要使用 `DBMS_MONITOR` 包追踪。

### 为当前会话设置标识符

```sql
--设置标识符
SQL> exec dbms_session.set_identifier('myid');

--查看标识符
SQL> select sid,serial#,username,client_identifier from v$session where client_identifier='myid';

       SID    SERIAL# USERNAME	 CLIENT_IDE
---------- ---------- ---------- ----------
       243	   2094      SYS	 myid
```

### 启用跟踪

```sql
--启用跟踪。第二个参数用于等待，第三个参数用于绑定变量。
SQL> exec dbms_monitor.client_id_trace_enable('myid',true,false);
```

### 运行测试 SQL 语句

测试 SQL 语句基本都是我们在 SQL 那节实验使用过的，这里不对每条语句做过多解释。

```sql
select * from student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id and student.s_id=99999;
select s_age,s_name from student where s_age between 20 and 50;
SELECT s_id,s_age,s_id+s_age,s_id-s_age,s_id*s_age,s_id/s_age FROM student;
SELECT * FROM student WHERE s_name LIKE '%2';
SELECT max(s_age),min(s_age) FROM student;
SELECT avg(grade),sum(grade) FROM sc WHERE s_id='1001';
SELECT count(s_id) FROM sc WHERE s_id=1001;
SELECT CONCAT(CONCAT(s_name,'''s sex is '),s_sex) "sex" FROM student WHERE s_id=1001;
SELECT s_id,count(*) FROM sc GROUP BY s_id;
SELECT s_id,sum(grade) FROM sc GROUP BY s_id;
SELECT c_id, sum(grade) FROM sc GROUP BY c_id HAVING sum(grade)>1000;
SELECT c_id, sum(grade) FROM sc GROUP BY c_id HAVING sum(grade)>200 order by sum(grade) desc;
SELECT * FROM student where rownum<50000;
SELECT s_id,s_age FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=1);
SELECT  * FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=(SELECT c_id FROM course WHERE c_time=(SELECT max(c_time) FROM course)));
```

> 提示：有些查询的结果集较多，按 `ctrl + c` 可以退出。

### 停止追踪

```sql
SQL> exec dbms_monitor.client_id_trace_disable('myid');

SQL> select value from v$diag_info where name='Default Trace File';

VALUE
--------------------------------------------------------
/u01/app/oracle/diag/rdbms/xe/xe/trace/xe_ora_1539.trc
```

### 使用 TKPROF 转换跟踪文件格式

虽然可以直接打开跟踪文件查看，但使用了 TKPROF 转换格式后查看更易阅读。

在 bash 命令行输入如下命令：

```bash
$ tkprof xe_ora_1539.trc myid.prf explain=sys/Syl12345

TKPROF: Release 12.1.0.2.0 - Development on Fri Mar 2 15:22:59 2018

Copyright (c) 1982, 2015, Oracle and/or its affiliates.  All rights reserved.
```

> 它会在跟踪目录生成一个 myid.prf 的文件。
>
> 关于 tkprof 工具还有其他的一些选项，可参考 [Generating Output Files Using SQL Trace and TKPROF](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/tgsql/performing-application-tracing.html#GUID-045E1093-E389-4F2A-94CB-820AF356C564) 。

文件中包含每条 SQL 语句解析，执行，获取这三个步骤的统计信息。以下截取部分输出内容：

```sql
$ cat /u01/app/oracle/diag/rdbms/xe/xe/trace/myid.prf

********************************************************************************
count    = number of times OCI procedure was executed
cpu      = cpu time in seconds executing
elapsed  = elapsed time in seconds executing
disk     = number of physical reads of buffers from disk
query    = number of buffers gotten for consistent read
current  = number of buffers gotten in current mode (usually for update)
rows     = number of rows processed by the fetch or execute call
********************************************************************************

SQL ID: 2asb5kfmmr5dn Plan Hash: 2626109014

select *
from
 student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id and
  student.s_id=99999


call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        1      0.00       0.00          0          0          0           0
Execute      1      0.00       0.00          0          0          0           0
Fetch        2      0.00       0.00          0          9          0           1
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        4      0.00       0.00          0          9          0           1

Misses in library cache during parse: 1
Optimizer mode: ALL_ROWS
Parsing user id: SYS
Number of plan statistics captured: 1

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
         1          1          1  NESTED LOOPS  (cr=9 pr=0 pw=0 time=56 us cost=5 size=45 card=1)
         1          1          1   NESTED LOOPS  (cr=8 pr=0 pw=0 time=59 us cost=5 size=45 card=1)
         1          1          1    NESTED LOOPS  (cr=7 pr=0 pw=0 time=49 us cost=4 size=34 card=1)
         1          1          1     TABLE ACCESS BY INDEX ROWID STUDENT (cr=3 pr=0 pw=0 time=29 us cost=2 size=23 card=1)
         1          1          1      INDEX UNIQUE SCAN PK_SID (cr=2 pr=0 pw=0 time=20 us cost=1 size=0 card=1)(object id 91979)
         1          1          1     TABLE ACCESS BY INDEX ROWID BATCHED SC (cr=4 pr=0 pw=0 time=19 us cost=2 size=11 card=1)
         1          1          1      INDEX RANGE SCAN PK_SCID (cr=3 pr=0 pw=0 time=15 us cost=1 size=0 card=1)(object id 91984)
         1          1          1    INDEX UNIQUE SCAN PK_CID (cr=1 pr=0 pw=0 time=9 us cost=0 size=0 card=1)(object id 91981)
         1          1          1   TABLE ACCESS BY INDEX ROWID COURSE (cr=1 pr=0 pw=0 time=3 us cost=1 size=11 card=1)
Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  Disk file operations I/O                        1        0.00          0.00
  SQL*Net message to client                       2        0.00          0.00
  SQL*Net message from client                     2        0.00          0.00
********************************************************************************
```

除了在 `prf` 中查看各 SQL 语句统计信息以外，我们还可以使用 `v$sqlarea` 视图找出需要优化的 SQL。

### 使用 V$SQLAREA 动态性能视图

```sql
SQL> select disk_reads,executions,disk_reads/decode(executions,0,1,executions) rds_exec_ratio,sql_text from v$sqlarea where sql_text like '%student%' order by disk_reads desc;

DISK_READS EXECUTIONS RDS_EXEC_RATIO SQL_TEXT
---------- ---------- -------------- --------------------------------------------------
       380	    1		 380        select s_age,s_name from student where s_age between 20 and                                     50
......
```

> - `disk_reads` ：硬盘读取次数的总和
> - `executions` ：总计执行次数
>
> 更多字段含义可参考 [v$sqlarea](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/V-SQLAREA.html#GUID-09D5169F-EE9E-4297-8E01-8D191D87BDF7) 。
>
> 这里只截取了一部分输出结果。可以看到这条语句的物理读取次数高达 380，我们需要优化此语句。
>
> 另外，还有一些其他动态性能视图可以用来查看消耗较高的 SQL ：
>
> - `V$SQL`
> - `V$SQLSTAT` 
> - `V$SESSMETRIC`
> - `DBA_HIST_SQLSTAT` 

找出了哪些 SQL 语句需要优化过后，我们需要对 SQL 语句进行分析，找出了问题所在，才好进行优化。

## 执行计划

Oracle 数据库执行 SQL 语句，会先生成一个执行计划，然后按照执行计划里的步骤顺序完成。

查看一个 SQL 语句的执行计划可使用 `EXPLAIN PLAN` 或者 `AUTOTRACE` 等工具。

### 使用 EXPLAIN PLAN

```sql
--生成 plan_table 表，存储执行计划
SQL> @?/rdbms/admin/utlxplan.sql
--查看 plan_table 表结构
SQL> desc plan_table;
--分析 sql 语句
SQL> explain plan for select * from student where s_age between 20 and 50;
--查看执行计划
SQL> select operation,options,object_name,id,parent_id,cost from plan_table;

OPERATION	     OPTIO OBJECT_NAM	      ID  PARENT_ID	  COST
-------------------- ----- ---------- ---------- ---------- ----------
SELECT STATEMENT			                      0		   106
TABLE ACCESS	     FULL  STUDENT	       1	  0	       106
```

> ****字段解释：****
>
> | 字段        | 说明                                     |
> | ----------- | ---------------------------------------- |
> | operation   | 在该步骤中执行的内部操作的名称           |
> | options     | 操作上的变化                             |
> | object_name | 操作的对象名                             |
> | id          | 分配给执行计划中每个步骤的编号           |
> | parent_id   | 在ID步骤的输出上操作的下一个执行步骤的ID |
> | cost        | 根据优化程序的查询方法估算的操作成本     |
>
> 查看更多字段含义可参考 [plan_table](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/PLAN_TABLE.html#GUID-0CAFEAD1-8C79-4200-8658-947D04BDFFE2) 。

根据 id 和 parent_id 可以整理出这样一个结构：`0----1` ，从输出结果可以看出对 student 表进行了全表扫描，这个查询的总成本是 106 。

下面补充一下执行计划的顺序，比如整理出的结构是这样：

```
0
|
1--------2
    |
    |----3-----4
            |
            |--5
```

寻找节点的顺序是自顶向下，自左向右。先寻找第一个没有子节点的节点，找到了 2，然后向下寻找到第二个没有子节点的节点 4，再向下找到同级的节点 5，最后回到父节点 3，向下没有和 3 同级的节点了，所以回到 3 的父节点 1，再回到节点 0 。所以整个执行顺序是 `2->4->5->3->1->0` 。

### 使用 AUTOTRICE

```sql
SQL> set serveroutput on;
--启用 autotrice
SQL> set autotrace trace;
```

> `set autotrace trace` 是不显示查询的输出结果。
>
> 除此之外还有一些其他选项，可参考 [Controlling the Autotrace Report](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sqpug/tuning-SQL-Plus.html#GUID-1425180A-9917-429E-B908-B217C0CAC3DD) 。

```sql
SQL> select s_name,s_age  from student where s_age between 20 and 50;

45379 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 2356778634

-----------------------------------------------------------------------------
| Id  | Operation	      | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |	        | 45379 |	531K|	106   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| STUDENT | 45379 |	531K|	106   (1)| 00:00:01 |
-----------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("S_AGE"<=50 AND "S_AGE">=20)


Statistics
----------------------------------------------------------
	  1  recursive calls
	  0  db block gets
       3402  consistent gets
	381  physical reads
	  0  redo size
    1172474  bytes sent via SQL*Net to client
      33826  bytes received via SQL*Net from client
       3027  SQL*Net roundtrips to/from client
	  0  sorts (memory)
	  0  sorts (disk)
      45379  rows processed
      
      
--关闭 autotrace
SQL> set autotrace off;
```

> autotrace 中执行计划以缩进来表示父子节点关系。展示了 SQL 语句的执行计划以及统计信息。从输出结果中我们也能看出有较高的执行成本（cost:106）以及物理读取数（physical reads:381）。

### EXPLAIN PLAN 和 AUTOTRACE 的区别

`EXPLAIN PLAN` 实际上并未真正执行 SQL 语句，所以在一些处理较大的数据时，使用它更为迅速。`AUTOTRACE` 直接设置启用，便能直接在执行时输出执行计划以及统计信息，更为方便，但是其实际上是真正执行了 SQL 语句，所以一些处理量较多的 SQL 语句可能会较慢。

## SQL 优化

表 student 有十万条数据，此处查询进行了全表扫描。我们可以建立 s_age 和 s_name 字段的索引，以提高查询速度。

```sql
--清除缓存。执行 SQL 语句的时候会生成缓存以便下一次执行相同语句更快，这一步是为了避免缓存对分析结果的影响。
SQL> alter system flush buffer_cache;

System altered.

--创建 s_age s_name 的索引
SQL> create index idx_stu on student(s_age,s_name);

Index created.

--分析索引
SQL> analyze index idx_stu compute statistics;

Index analyzed.

--执行查询语句
SQL> select s_name,s_age from student where s_age between 20 and 50;

45379 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1512023234

--------------------------------------------------------------------------------
| Id  | Operation	         | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |	       | 45379 |   531K|    89	 (2)| 00:00:01 |
|*  1 |  INDEX FAST FULL SCAN| IDX_STU | 45379 |   531K|    89	 (2)| 00:00:01 |
--------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("S_AGE"<=50 AND "S_AGE">=20)


Statistics
----------------------------------------------------------
	  1  recursive calls
	  0  db block gets
       3343  consistent gets
	  0  physical reads
	  0  redo size
    1208810  bytes sent via SQL*Net to client
      33826  bytes received via SQL*Net from client
       3027  SQL*Net roundtrips to/from client
	  0  sorts (memory)
	  0  sorts (disk)
      45379  rows processed

```

> 使用索引以后，我们可以看到执行成本从 106 降到了 89 。更明显的是物理读取数从 381 降到了 0 。

对于 SQL 进行监测和优化的整个步骤就结束了。下面补充一些 SQL 语句格式规范。

## SQL 语句格式规范

我们以三条 SQL 语句为例：

```sql
--语句 1
select * from student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id and student.s_id=99999;

--语句 2
SELECT  * FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=(SELECT c_id FROM course WHERE c_time=(SELECT max(c_time) FROM course)));

--语句 3
SELECT c_id, sum(grade) FROM sc GROUP BY c_id HAVING sum(grade)>1000;
```

下面是分别对每条语句进行格式优化：

```sql
--优化 1
SELECT *
FROM student,
  course,
  sc
WHERE sc.s_id   =student.s_id
AND sc.c_id     =course.c_id
AND student.s_id=99999;

--优化 2
SELECT *
FROM student
WHERE s_id IN
  (SELECT s_id
  FROM sc
  WHERE c_id=
    (SELECT c_id FROM course WHERE c_time=
      (SELECT MAX(c_time) FROM course
      )
    )
  );
  
--优化 3
SELECT c_id,
  SUM(grade)
FROM sc
GROUP BY c_id
HAVING SUM(grade) >1000;
```

> 关键字和函数名使用大写并且为每行首个字母。字段太多的时候可以分行书写。

格式优化过后，查看起来更易阅读，并且有助于后期维护。

## 总结

- 追踪 SQL
    - 为当前会话设置标识符
    - 启用跟踪
    - 运行测试 SQL 语句
    - 停止追踪
    - 使用 TKPROF 转换跟踪文件格式
    - 使用 V$SQLAREA 动态性能视图
- 执行计划
    - 使用 EXPLAIN PLAN
    - 使用 AUTOTRICE
    - EXPLAIN PLAN 和 AUTOTRACE 的区别
- SQL 优化
- SQL 语句格式规范