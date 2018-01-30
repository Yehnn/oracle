# SQL 与 PL/SQL

## 1. 实验介绍

### 1.1 实验内容



### 1.2 实验知识点

+ 数据库简介
+ SQL 简介
+ 安装 MySQL

## 2. SQL 和 PL/SQL 简介

`SQL` 是 `Structured Query Language` 的首字母缩写，意为结构化查询语言，它可以告诉 Oracle 对哪些信息进行选择，插入，更新和删除。相信大家已经很熟悉，在 mysql 和 sqlserver 中我们也经常使用。

`PL/SQL` 是 Oracle 对 SQL 的过程化语言扩展，是一种便携式，高性能的事务处理语言。它将 SQL 的数据操作能力与过程语言的处理能力结合起来。（更多有关 PL/SQL 介绍可参考[官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/overview.html#GUID-17166AA4-14DC-48A6-BE92-3FC758DAA940) ）

## 3. 创建示例表

首先，试着用前面学到的内容创建如下 3 个示例表：

**学生表（student）**：



| 学号(s_id) | 姓名(s_name)    | 性别(s_sex) | 年龄(s_age) |
| -------- | ------------- | --------- | --------- |
| 1001     | shiyanlou1001 | man       | 10        |
| 1002     | shiyanlou1002 | woman     | 20        |
| 1003     | shiyanlou1003 | man       | 18        |
| 1004     | shiyanlou1004 | woman     | 40        |
| 1005     | shiyanlou1005 | man       | 17        |

**课程表（course）**：

| 课程号(c_id) | 课程名(c_name) | 课时(c_time) |
| --------- | ----------- | ---------- |
| 1         | java        | 13         |
| 2         | python      | 12         |
| 3         | c           | 10         |
| 4         | spark       | 15         |

**选课表（sc）**:

| 学号(s_id) | 课程号(c_id) | 成绩(grade) |
| -------- | --------- | --------- |
| 1001     | 3         | 70        |
| 1001     | 1         | 20        |
| 1002     | 1         | 100       |
| 1001     | 4         | 96        |
| 1002     | 2         | 80        |
| 1003     | 3         | 75        |
| 1002     | 4         | 80        |





## PLSQL 

http://study.163.com/course/introduction.htm?courseId=1543006#/courseDetail?tab=1



## 5. 总结

在本节内容中，我们简单介绍了 MySQL 数据库的安装，服务的启动，以及怎么连接到数据库和如何修改配置。