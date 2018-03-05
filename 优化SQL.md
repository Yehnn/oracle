# 优化 SQL

## 实验介绍

### 实验内容

SQL 优化实际上就是让 SQL 执行得更快，实现这个目标我们需要减少 I/O 操作，增加系统的吞吐量，也就是单位时间内访问的资源量。

### 实验知识点

+ ​




## 执行计划

Oracle 数据库执行 SQL 语句，会先生成一个执行计划，然后按照执行计划里的步骤顺序完成。



使用 sysdba 登入实例：

```bash
$ sudo su oracle
$ sqlpus / as sysdba
```



自动 SQL 调优

自动 SQL 调优是一个预置的后台数据库作业，它会分析 AWR 中消耗资源最高的 SQL 语句，使用 SQL 调优顾问（sql tuning advice）为每条语句生成调优建议，默认每天运行一次。

确定是否启用自动 SQL 调优：

```sql
SQL> select client_name,status from dba_autotask_client order by client_name;

CLIENT_NAME                                STATUS
---------------------------------------- --------
auto optimizer stats collection           ENABLED
auto space advisor                        ENABLED
sql tuning advisor                        ENABLED
```

这里可以看到都是 enable ，说明默认都启动了。如果某项服务没有启动，可使用如下命令启动：

```sql
--关闭 sql 调优顾问
SQL> exec dbms_auto_task_admin.disable(client_name => 'sql tuning advisor',operation => NULL,window_name => NULL);
--启动 sql 调优顾问
SQL> exec dbms_auto_task_admin.enable(client_name => 'sql tuning advisor',operation => NULL,window_name => NULL);
```



```plsql
declare
v_task varchar2(100);
begin
v_task := dbms_sqltune.create_tuning_task(sql_text => 'select * from autotest order by object_name',task_name => 'autotest');
end;
/
select task_name,status from user_advisor_log;
exec dbms_sqltune.execute_tuning_task(task_name=>'autotest');
select task_name,status from user_advisor_tasks where task_name='autotest';
select dbms_sqltune.report_tuning_task('autotest') from dual;
exec dbms_sqltune.drop_tuning_task('autotest');
```



explain autotrace

explain 没有真正执行。

测试表：	

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

BEGIN
  INSERT INTO course VALUES(1, 'java', 13);
  INSERT INTO course VALUES(2, 'python', 12);
  INSERT INTO course VALUES(3, 'c', 10);
  INSERT INTO course VALUES(4, 'spark', 15);
  INSERT INTO course VALUES(5, 'php', 20);
  INSERT INTO course VALUES(6, 'hadoop', 11);
  INSERT INTO course VALUES(7, 'oracle', 22);
  FOR i IN 1..10000 LOOP
    INSERT INTO student VALUES(i,'syl'||i,DECODE(TRUNC(DBMS_RANDOM.VALUE(0,2)),0,'man',1,'female'),TRUNC(DBMS_RANDOM.VALUE(12,80)));
    INSERT INTO sc VALUES(i,TRUNC(DBMS_RANDOM.VALUE(1,8)),TRUNC(DBMS_RANDOM.VALUE(0,101)));
  end loop;
  commit;
end;
/
```

### 使用 explain：

```sql
SQL> @?/rdbms/admin/utlxplan.sql

SQL> desc plan_table;

SQL> explain plan for select * from student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id;

SQL> select operation,options,object_name,id,parent_id,cost from plan_table;

OPERATION	          OPTIONS	   OBJECT_NAME		ID     PARENT_ID	    COST
-------------------- ---------- --------------- ---------- ---------- ----------
SELECT STATEMENT					                0		                 22
HASH JOIN						                    1	        0	         22
TABLE ACCESS	        FULL	    STUDENT 		2	        1	         12
HASH JOIN						                    3	        1	         10
TABLE ACCESS	        FULL	    COURSE			4	        3	          2
TABLE ACCESS	        FULL	      SC			5	        3	          8

6 rows selected.
```

> **字段解释：**
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

根据 id 和 parent_id ，我们可以整理出这样的树状结构：

```
0
|
1--------2
    |
    |----3-----4
            |
            |--5
```

寻找节点的顺序是自顶向下，自左向右。先寻找第一个没有子节点的节点，找到了 2，然后向下寻找到第二个没有子节点的节点 4，再向下找到同级的节点 5，最后回到父节点 3，向下没有和 3 同级的节点了，所以回到 3 的父节点 1，再回到节点 0 。

所以整个执行顺序是 `2->4->5->3->1->0` 。

详细的顺序如下：

1. 检索 STUDENT 表的所有行
2. 检索 COURSE 表的所有行
3. 检索 SC 表的所有行
4. 联接 COURSE 表和 SC 表
5. 联接 STUDENT 表和步骤 4 中的结果集

这个查询的总成本为 22 ，操作成本越接近 1 越好。

### 使用 autotrace：

```sql
SQL> set serveroutput on;
SQL> set autotrace trace;
```

> `set autotrace trace` 是不显示查询的输出结果。
>
> 除此之外还有一些其他选项，可参考 [Controlling the Autotrace Report](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sqpug/tuning-SQL-Plus.html#GUID-1425180A-9917-429E-B908-B217C0CAC3DD) 。

```sql
SQL> select * from student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id;

Execution Plan
----------------------------------------------------------
Plan hash value: 787053410

-------------------------------------------------------------------------------
| Id  | Operation	        | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |	      | 10000 |  1191K|    22	(0)| 00:00:01 |
|*  1 |  HASH JOIN	        |	      | 10000 |  1191K|    22	(0)| 00:00:01 |
|   2 |   TABLE ACCESS FULL | STUDENT | 10000 |   439K|    12	(0)| 00:00:01 |
|*  3 |   HASH JOIN	        |	      | 10000 |   751K|    10	(0)| 00:00:01 |
|   4 |    TABLE ACCESS FULL| COURSE  |     7 |   266 |     2	(0)| 00:00:01 |
|   5 |    TABLE ACCESS FULL| SC      | 10000 |   380K|     8	(0)| 00:00:01 |
-------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("SC"."S_ID"="STUDENT"."S_ID")
   3 - access("SC"."C_ID"="COURSE"."C_ID")

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)


Statistics
----------------------------------------------------------
	 23  recursive calls
	  0  db block gets
	826  consistent gets
	  0  physical reads
	  0  redo size
 558081  bytes sent via SQL*Net to client
   7878  bytes received via SQL*Net from client
	668  SQL*Net roundtrips to/from client
	  3  sorts (memory)
	  0  sorts (disk)
  10000  rows processed
```

autotrace 中执行计划以缩进来表示父子节点关系。



## 添加索引优化

```sql
SQL> select * from student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id and student.s_name='syl1001';

    S_ID S_NAME		S_SEX	S_AGE	    C_ID     C_NAME   C_TIME     S_ID	C_ID  GRADE
-------- ------- ---------- ------- ---------- --------- ---------- ----- -------- ------
   1001  syl1001    female	 25	       7         oracle    22        1001	 7        78
```

![图片描述](https://dn-simplecloud.shiyanlou.com/uid/8797/1519962987120.png-wm)

添加索引：

```sql
--创建索引
SQL> create index idx_stu_name on student(s_name);

Index created

--查看索引
SQL> select index_name,index_type,table_name from user_indexes where table_name='STUDENT';

INDEX_NAME   INDEX_TYPE TABLE_NAME
------------ ---------- ----------
IDX_STU_NAME NORMAL	STUDENT
PK_SID	     NORMAL	STUDENT
```

重新查询所得执行计划：

![图片描述](https://dn-simplecloud.shiyanlou.com/uid/8797/1519962987476.png-wm)

## 追踪 SQL：

### 使用 sql trace： 

```sql
--是否启用定时统计信息收集
SQL> show parameter statistics;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
optimizer_use_pending_statistics     boolean	 FALSE
statistics_level		     string	 TYPICAL
timed_os_statistics		     integer	 0
timed_statistics		     boolean	 TRUE

--查询追踪目录的位置
SQL> select name,value from v$diag_info where name='Diag Trace';

NAME	   VALUE
---------- ----------------------------------------
Diag Trace /u01/app/oracle/diag/rdbms/xe/xe/trace

--转储文件大小是否无限制
SQL> select name,value from v$parameter where name='max_dump_file_size';

NAME			       VALUE
------------------------------ --------------------------------------------------
max_dump_file_size	       unlimited
```

> `timed_statistics` 为 `true` 说明启用了定时统计信息收集
>
> `max_dump_file_size` 为 `unlimited` 说明无限制。

不推荐 sql trace 了，过时了。推荐 DBMS_MONITOR 包。

### 使用 DBMS_MONITOR

```sql
--为当前会话设置标识符
SQL> exec dbms_session.set_identifier('myid');

--启用跟踪。第二个参数用于等待，第三个参数用于绑定变量。
SQL> exec dbms_monitor.client_id_trace_enable('myid',true,false);


SQL> select count(*) from student;

  COUNT(*)
----------
     10000

--停止跟踪
SQL> exec dbms_monitor.client_id_trace_disable('myid');

SQL> select value from v$diag_info where name='Default Trace File';

VALUE
--------------------------------------------------
/u01/app/oracle/diag/rdbms/xe/xe/trace/xe_ora_515.trc
```

### 使用 TKPROF 转换跟踪文件格式

虽然可以直接打开跟踪文件查看，但使用了 TKPROF 转换格式后查看更易阅读。

在 bash 命令行输入如下命令：

```bash
$ tkprof xe_ora_515.trc myid.prf explain=sys/Syl12345;

TKPROF: Release 12.1.0.2.0 - Development on Fri Mar 2 15:22:59 2018

Copyright (c) 1982, 2015, Oracle and/or its affiliates.  All rights reserved.
```

> 它会在跟踪目录生成一个 myid.prf 的文件。
>
> 关于 tkprof 工具还有其他的一些选项，可参考 [Generating Output Files Using SQL Trace and TKPROF](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/tgsql/performing-application-tracing.html#GUID-045E1093-E389-4F2A-94CB-820AF356C564) 。

文件中包含每条 SQL 语句解析，执行，获取这三个步骤的统计信息。

```sql
$ cat /u01/app/oracle/diag/rdbms/xe/xe/trace/myid.prf

SQL ID: 59ns3qkxx2671 Plan Hash: 482858077

select count(*) from student

call     count       cpu    elapsed       disk      query    current        rows
------- ------  -------- ---------- ---------- ---------- ----------  ----------
Parse        2      0.00       0.02          0         42          0           0
Execute      2      0.00       0.00          0          0          0           0
Fetch        4      0.00       0.00         18         50          0           2
------- ------  -------- ---------- ---------- ---------- ----------  ----------
total        8      0.00       0.02         18         92          0           2

Misses in library cache during parse: 1
Optimizer mode: ALL_ROWS
Parsing user id: SYS
Number of plan statistics captured: 2

Rows (1st) Rows (avg) Rows (max)  Row Source Operation
---------- ---------- ----------  ---------------------------------------------------
         1          1          1  SORT AGGREGATE (cr=25 pr=9 pw=0 time=1678 us)
     10000      10000      10000   INDEX FAST FULL SCAN PK_SID (cr=25 pr=9 pw=0 time=1850 us cos
t=7 size=0 card=10000)(object id 91979)


Elapsed times include waiting on following events:
  Event waited on                             Times   Max. Wait  Total Waited
  ----------------------------------------   Waited  ----------  ------------
  Disk file operations I/O                        2        0.00          0.00
  SQL*Net message to client                       4        0.00          0.00
  db file sequential read                         1        0.00          0.00
  db file scattered read                          3        0.00          0.00
  SQL*Net message from client                     4       28.09         44.82
```

从统计信息中可以看出物理读取（disk 列）为 18，总读取数量（query 列）为 92，内存读取是总读取数减去物理读取数（92-18），也就是 74。当物理读取数过高时，我们就需要考虑优化该条 SQL 语句了。

更多有关 TKPROF 内容可参考 [Guidelines for Interpreting TKPROF Output](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/tgsql/performing-application-tracing.html#GUID-A92E180C-8F2C-4864-ABFC-8439CEFFE368) 和 [Generating Output Files Using SQL Trace and TKPROF](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/tgsql/performing-application-tracing.html#GUID-045E1093-E389-4F2A-94CB-820AF356C564) 。







## 总结

