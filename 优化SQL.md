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

使用 explain：

```sql
SQL> @?/rdbms/admin/utlxplan.sql

SQL> desc plan_table;

SQL> explain plan for select * from student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id;

SQL> select operation,options,object_name,id,parent_id from plan_table;

OPERATION             OPTIONS   OBJECT_NAME   ID     PARENT_ID
-------------------- ---------- ---------- ---------- ----------
SELECT STATEMENT                               0
HASH JOIN                                      1          0
TABLE ACCESS          FULL       STUDENT       2          1
HASH JOIN                                      3          1
TABLE ACCESS          FULL       COURSE        4          3
TABLE ACCESS          FULL         SC          5          3
```

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

使用 autotrace

```sql
SQL> set serveroutput on;
SQL> set autotrace on;
SQL> select * from student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id;

```







## 总结

