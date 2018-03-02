# 优化 SQL

## 实验介绍

### 实验内容

SQL 优化实际上就是让 SQL 执行得更快，实现这个目标我们需要减少 I/O 操作，增加系统的吞吐量，也就是单位时间内访问的资源量。

### 实验知识点

+ ​




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

## 追踪 SQL

追踪 SQL 是为了找出那些执行时间缓慢，消耗资源的 SQL 语句。可以使用 `SQL TRACE` 工具和 `DBMS_MONITOR` 包。推荐使用 `DBMS_MONITOR` 包，它具有更高的灵活性。我们下面主要使用 `DBMS_MONITOR` 包追踪。

### 为当前会话设置标识符

```sql
--设置标识符
SQL> exec dbms_session.set_identifier('myid');

--查看标识符
SQL> select sSQL> select sid,serial#,username,client_identifier from v$session where client_identifier='myid';

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

```sql
select * from student,course,sc where sc.s_id=student.s_id and sc.c_id=course.c_id and student.s_id=99999;
select * from student where s_age between 20 and 50;
SELECT s_id,s_age,s_id+s_age,s_id-s_age,s_id*s_age,s_id/s_age FROM student;
SELECT * FROM student WHERE s_name LIKE '%2';
SELECT max(s_age),min(s_age) FROM student;
SELECT avg(grade),sum(grade) FROM sc WHERE s_id='1001';
SELECT count(s_id) FROM sc WHERE s_id=1001;

```

> 提示：有些查询的结果集较多，按 `ctrl + c` 可以退出。





## 总结

