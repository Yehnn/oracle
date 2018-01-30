# SQL 与 PL/SQL

## 实验介绍

### 实验内容



### 实验知识点

+ 数据库简介
+ SQL 简介
+ 安装 MySQL

## SQL 和 PL/SQL 简介

`SQL` 是 `Structured Query Language` 的首字母缩写，意为结构化查询语言，它可以告诉 Oracle 对哪些信息进行选择，插入，更新和删除。相信大家已经很熟悉，在 mysql 和 sqlserver 中我们也经常使用。

`PL/SQL` 是 Oracle 对 SQL 的过程化语言扩展，是一种便携式，高性能的事务处理语言。它将 SQL 的数据操作能力与过程语言的处理能力结合起来。（更多有关 PL/SQL 介绍可参考[官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/overview.html#GUID-17166AA4-14DC-48A6-BE92-3FC758DAA940) ）

## SQL

### 创建示例表

首先，试着用前面学到的内容创建如下 3 个示例表：

**学生表（student）**：

| 字段     | 类型           | 约束             | 默认值  |
| ------ | ------------ | -------------- | ---- |
| s_id   | number       | 主键             |      |
| s_name | varchar2(20) | not null       |      |
| s_sex  | varchar2(10) | 为 man 或者 woman | man  |
| s_age  | number       | not null       |      |

插入如下数据：

| 学号(s_id) | 姓名(s_name)    | 性别(s_sex) | 年龄(s_age) |
| -------- | ------------- | --------- | --------- |
| 1001     | shiyanlou1001 | man       | 10        |
| 1002     | shiyanlou1002 | woman     | 20        |
| 1003     | shiyanlou1003 | man       | 18        |
| 1004     | shiyanlou1004 | woman     | 40        |
| 1005     | shiyanlou1005 | man       | 17        |

**课程表（course）**：

| 字段     | 类型          | 约束          |
| ------ | ----------- | ----------- |
| c_id   | number      | 主键          |
| c_name | varchar(20) | not null，唯一 |
| c_time | number      |             |

插入如下数据：

| 课程号(c_id) | 课程名(c_name) | 课时(c_time) |
| --------- | ----------- | ---------- |
| 1         | java        | 13         |
| 2         | python      | 12         |
| 3         | c           | 10         |
| 4         | spark       | 15         |

**选课表（sc）**:

| 字段    | 类型     | 约束                        |
| ----- | ------ | ------------------------- |
| s_id  | number | 主键，外键（来自 student 表的 s_id） |
| c_id  | number | 主键，外键（来自 cource 表的 c_id）  |
| grade | number |                           |

插入如下数据：

| 学号(s_id) | 课程号(c_id) | 成绩(grade) |
| -------- | --------- | --------- |
| 1001     | 3         | 70        |
| 1001     | 1         | 20        |
| 1002     | 1         | 100       |
| 1001     | 4         | 96        |
| 1002     | 2         | 80        |
| 1003     | 3         | 75        |
| 1002     | 4         | 80        |

以下是创建示例表的脚本：

```sql
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

desc student;
desc course;
desc sc;

INSERT INTO student VALUES(1001, 'shiyanlou1001', 'man', 10);
INSERT INTO student VALUES(1002, 'shiyanlou1002', 'woman', 20);
INSERT INTO student VALUES(1003, 'shiyanlou1003', 'man', 18);
INSERT INTO student VALUES(1004, 'shiyanlou1004', 'woman', 40);
INSERT INTO student VALUES(1005, 'shiyanlou1005', 'man', 17);

INSERT INTO course VALUES(1, 'java', 13);
INSERT INTO course VALUES(2, 'python', 12);
INSERT INTO course VALUES(3, 'c', 10);
INSERT INTO course VALUES(4, 'spark', 15);

INSERT INTO sc VALUES(1001, 3, 70);
INSERT INTO sc VALUES(1001, 1, 20);
INSERT INTO sc VALUES(1002, 1, 100);
INSERT INTO sc VALUES(1001, 4, 96);
INSERT INTO sc VALUES(1002, 2, 80);
INSERT INTO sc VALUES(1003, 3, 75);
INSERT INTO sc VALUES(1002, 4, 80);

commit;
```

### 查询


查询年龄在 20-50 岁的学生：

```sql
SQL> col s_name for a20
SQL> select * from student where s_age between 20 and 50;
```

输出结果如下：

```sql
       S_ID S_NAME               S_SEX                     S_AGE
---------- -------------------- -------------------- ----------
      1002 shiyanlou1002        woman                        20
      1004 shiyanlou1004        woman                        40
```

除了上面的 `between ... and ...` ，还有一些其他的运算符：

| 操作符                  | 释义             |
| -------------------- | -------------- |
| `=`                  | 等于             |
| `<>`                 | 不等于            |
| `!=`                 | 不等于            |
| `>`                  | 大于             |
| `>=`                 | 大于等于           |
| `<`                  | 小于             |
| `<=`                 | 小于等于           |
| `BETWEEN ... AND...` | 检查值的范围         |
| `IN`                 | 检查是否在一组值中      |
| `NOT IN`             | 检查一个值是否不在一组值中  |
| `IS {TRUE|FALSE}`    | 判断 bool 值      |
| `IS NULL`            | `NULL` 值测试     |
| `IS NOT NULL`        | `NOT NULL` 值测试 |
| `LIKE`               | 模式匹配           |
| `NOT LIKE`           | 否定匹配           |

另外，我们还可以使用多个表达式进行逻辑运算。逻辑运算符如下表：

| 逻辑运算符     | 释义   |
| --------- | ---- |
| `OR, ||`  | 或    |
| `AND, &&` | 与    |
| `NOT, !`  | 非    |
| `XOR`     | 异或   |

例如，我们也可以通过 `AND` 查找年龄在 `20~50` 岁的学生。

```bash
SQL> SELECT * FROM student WHERE s_age>=20 AND s_age<=50;
```
除了上述所列举的运算符和表达式之外，我们还可以进行一些数学的计算操作，例如加减乘除等，如下示例，我们将 `student` 表中的 `s_id` 和 `s_age` 分别进行加减乘除操作。

```sql
SQL> SELECT s_id,s_age,s_id+s_age,s_id-s_age,s_id*s_age,s_id/s_age FROM student;

      S_ID      S_AGE S_ID+S_AGE S_ID-S_AGE S_ID*S_AGE S_ID/S_AGE
---------- ---------- ---------- ---------- ---------- ----------
      1001         10       1011        991      10010      100.1
      1002         20       1022        982      20040       50.1
      1003         18       1021        985      18054 55.7222222
      1004         40       1044        964      40160       25.1
      1005         17       1022        988      17085 59.1176471
```

### 通配符

在上述内容中，我们有提到 `LIKE`，它是一个字符串比较函数，用于 `LIKE` 的通配符有两个：

+ `%` 百分号，匹配任意数量的字符

+ `_` 下划线，匹配一个字符

例如，我们查看学生表中 `s_name` 以 `2` 结尾的学生信息：

```sql
SQL> SELECT * FROM student WHERE s_name LIKE '%2';

      S_ID S_NAME               S_SEX                     S_AGE
---------- -------------------- -------------------- ----------
      1002 shiyanlou1002        woman                        20
```

### 函数

#### MAX 和 MIN

查找列的最大值和最小值。例如查找学生表中的年龄的最大值和最小值：

```bash
SQL> SELECT max(s_age),min(s_age) FROM student;

MAX(S_AGE) MIN(S_AGE)
---------- ----------
        40         10
```

#### SUM 及 AVG

`SUM` 和 `AVG` 分别可以用来求和以及求平均值。

例如，查找选课表中，`s_id=1001` 学生成绩的总分及平均值：

```bash
SQL> SELECT avg(grade),sum(grade) FROM sc WHERE s_id='1001';

AVG(GRADE) SUM(GRADE)
---------- ----------
        62        186
```

除此之外，我们还可以使用 `DISTINCT` 修饰符指定从结果集中删除重复的行，对应的是 `ALL` ，为默认项。通过如下示例来了解：

```bash
SQL> SELECT grade FROM sc;

     GRADE
----------
        70
        20
       100
        96
        80
        75
        80
  已选择 7 行。

# 重复的 80 的记录会被删除
SQL> SELECT DISTINCT grade FROM sc;

     GRADE
----------
       100
        70
        20
        96
        75
        80

已选择 6 行。
```

#### COUNT

`COUNT` 函数用于计数。

例如，我们统计选课表中 `s_id=1001` 有多少条记录，就可以使用 `count`

```
SQL> SELECT count(s_id) FROM sc WHERE s_id=1001;

COUNT(S_ID)
-----------
          3
```

#### CONCAT

`CONCAT` 是一个字符串函数。用于连接字符串。语法如下：

```sql
CONCAT(char1,char2);
```

意为连接字符串 char1 和 char2  。

例如：把 `student` 表中 `s_id=1001` 对应的 `s_name` 和 `s_sex` 字段连接。

```bash
SQL> SELECT CONCAT(CONCAT(s_name,'''s sex is '),s_sex) "sex" FROM student WHERE s_id=1001;
sex
-------------------------------------------------------------------
shiyanlou1001's sex is man
```

想了解更多有关函数的内容可以参考 [SQL 函数](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sqlrf/COUNT.html#GUID-AEF08B79-024D-4E3A-B362-9715FB011776)

## 分组排序

关于分组我们会学习到 `SELECT` 的两个子句，分别为：

- `GROUP BY`
- `HAVING`

详细的语法格式对于初学者来说并不友好，下面我们通过实例来讲解相关的内容。

### GROUP BY

分组(`GROUP BY`) 功能，有时也称聚合，一些函数可以对分组数据进行操作，例如我们上述所列的 `AVG` `SUM` 都有相关的功能，不过我们并未使用分组，所以默认使用所有的数据进行操作。首先我们描述聚合的使用方法：

```bash
[GROUP BY {col_name | expr | position} [ASC | DESC], ...]
```

如上所述，分组的标准可以为以下三种：

- 字段名(`col_name`)
- 表达式(`expr`)
- 位置(`position`)。

我们可以选择上面的一种进行分组，也可以重复多个，或者综合使用。

例如，我们根据字段名 `s_id` 进行分组：

```bash
mysql> SELECT * FROM sc GROUP BY s_id;
+------+------+-------+
| s_id | c_id | grade |
+------+------+-------+
| 1001 |    1 |    20 |
| 1002 |    1 |   100 |
| 1003 |    3 |    75 |
+------+------+-------+
```

如上所示，我们根据学生 id ，即 `s_id` 进行分组后，我们便只能查看到不同学生的第一条数据，不会有重复的 `s_id` 记录显示，我们可以尝试去掉 `GROUP BY` 字句做对比。

但是这样查询出来的数据意义不大，所以我们经常会搭配使用一些能够对一组数据进行操作的函数，例如，我们根据 `s_id` 进行分组后查询学生的总成绩，使用 `SUM` 函数：

```bash
mysql> SELECT s_id,sum(grade) FROM sc GROUP BY s_id;
+------+------------+
| s_id | sum(grade) |
+------+------------+
| 1001 |        186 |
| 1002 |        260 |
| 1003 |         75 |
+------+------------+
```

除此之外，我们还可以使用 `ASC` 或者 `DESC` 描述符来指定升序或者降序显示结果集，`ASC` 是默认选项，我们以 `DESC` 做如下示例：

```bash
mysql> SELECT s_id,sum(grade) FROM sc GROUP BY s_id DESC;
+------+------------+
| s_id | sum(grade) |
+------+------------+
| 1003 |         75 |
| 1002 |        260 |
| 1001 |        186 |
+------+------------+
```

上面是使用 `col_name` 的方式，这里我们还可以使用表达式的方式，更明确的指定筛选的条件：

```bash
mysql> SELECT sum(grade) FROM sc GROUP BY s_id=1001;
+------------+
| sum(grade) |
+------------+
|        335 |
|        186 |
+------------+
```

如上所示的使用表达式的方式，第一行数据代表 `s_id` 不等于 `1001` 的成绩之和，第二行代表 `s_id` 等于 `1001` 的成绩之和。

最后一种使用位置参数的方式，这里的位置参数代表的是要查询字段的位置，如下所示，`1` 对应 `c_id`。

```bash
mysql> SELECT c_id,sum(grade) FROM sc GROUP BY 1;
+------+------------+
| c_id | sum(grade) |
+------+------------+
|    1 |        120 |
|    2 |         80 |
|    3 |        145 |
|    4 |        176 |
+------+------------+
```

另外，我们还可以多个组合在一起使用，对于我们的选课表 `sc` 而言，如果使用 `s_id` 以及 `c_id` 进行分组，则得到的是所有的数据，因为我们使用 `s_id` 以及 `c_id` 作为主键，所以因此不会有相同的一组值可以进行分组，得到的是全部的数据。

如语法中所示，多个一起使用时使用 `逗号` 进行分隔。这里我们使用 `s_id` 以及 `grade` 一起作为分组的标准,如下所示：

```bash
mysql> SELECT s_id, c_id, grade, sum(grade) FROM sc GROUP BY s_id,grade;
+------+------+-------+------------+
| s_id | c_id | grade | sum(grade) |
+------+------+-------+------------+
| 1001 |    1 |    20 |         20 |
| 1001 |    3 |    70 |         70 |
| 1001 |    4 |    96 |         96 |
| 1002 |    2 |    80 |        160 |
| 1002 |    1 |   100 |        100 |
| 1003 |    3 |    75 |         75 |
+------+------+-------+------------+
```

### HAVING

除了可以对数据进行分组之外，我们还可以对分组数据进行过滤，使用 `HAVING` 子句，`HAVING` 跟 `WHERE` 的用法类似。两者在大多数时候都能起到相同的作用，如下示例

```bash
mysql> SELECT * FROM student HAVING s_id=1001;
+------+---------------+-------+-------+
| s_id | s_name        | s_sex | s_age |
+------+---------------+-------+-------+
| 1001 | shiyanlou1001 | man   |    10 |
+------+---------------+-------+-------+
1 row in set (0.00 sec)

mysql> SELECT * FROM student WHERE s_id=1001;
+------+---------------+-------+-------+
| s_id | s_name        | s_sex | s_age |
+------+---------------+-------+-------+
| 1001 | shiyanlou1001 | man   |    10 |
+------+---------------+-------+-------+
1 row in set (0.00 sec)
```

但是对于 `HAVING` 和 `WHERE` 来讲，`HAVING` 可以引用 `SUM AVG` 等函数，而 `WHERE` 则不能，即 `HAVING` 一般针对 `分组`，而 `WHERE` 针对的是 `行`。**即便很多时候两者都能起到同样的作用，你也不应该混用他们。**

如下示例，我们从选课表中筛选出选课总成绩大于 `100` 分的学生：

```bash
mysql> SELECT s_id, sum(grade) FROM sc GROUP BY s_id HAVING sum(grade)>100;
+------+------------+
| s_id | sum(grade) |
+------+------------+
| 1001 |        186 |
| 1002 |        260 |
+------+------------+
```

### ORDER BY

`ORDER BY` 用于对数据进行排序，使用方式跟 `GROUP BY` 一样：

```bash
[ORDER BY {col_name | expr | position} [ASC | DESC], ...]
```

这里我们可以将上述的查询语法，分组，以及排序综合起来，如下所示：

```bash
SELECT  [ALL | DISTINCT]
col_name[,col_name...] FROM tbl_name [WHERE where_condition]
[GROUP BY {col_name | expr | position} [ASC | DESC], ...]
[HAVING where_condition]
[ORDER BY {col_name | expr | position} [ASC | DESC], ...]
```

上面的示例有一些复杂，部分子句并不是必须项，不过我们可以大致总结出 `SELECT` 子句的使用顺序，如下：

```bash
SELECT
FROM
WHERE
GROUP BY
HAVING
ORDER BY
```

下面我们来综合示例，例如，我们将选课表 `sc` 的数据根据 `s_id` 进行分组，获得 `s_id` 以及对应的总成绩 `sum(grade)` 列，并给 `sum(grade)` 取一个别名为 `sum_grade`，然后筛选出 `sum_grade >100` 的分组，并且根据 `sum_grade` 进行降序排序，如下：

```bash
mysql> SELECT s_id,sum(grade) AS sum_grade FROM sc GROUP BY s_id HAVING sum_grade>100 ORDER BY sum_grade DESC;
+------+-----------+
| s_id | sum_grade |
+------+-----------+
| 1002 |       260 |
| 1001 |       186 |
+------+-----------+
```

由于在选课表中，我们的数据并不够多，使用不同的分组方式和排序方式显示的结果并不够直观，但是对于了解分组和排序的操作来说已经足够，同学们可以自己运用前面学习的插入操作，插入更多的数据，来进行分组和排序的练习。

### LIMIT

最后，我们还可以对返回的结果集进行限制，使用 `LIMIT` 。

`LIMIT` 可以使用一个或者两个非负的整数作为参数，他们的区别如下：

```bash
LIMIT 2   代表返回结果集的前 2 行
LIMIT 2,3  代表从第三行开始（因为下标从 0 开始，所以这里的 2 代表第三行），返回接下来的三行内容，即 3,4,5 行。
```

如下示例：

```bash
mysql> SELECT * FROM student LIMIT 2;
+------+---------------+-------+-------+
| s_id | s_name        | s_sex | s_age |
+------+---------------+-------+-------+
| 1001 | shiyanlou1001 | man   |    10 |
| 1002 | shiyanlou1002 | woman |    20 |
+------+---------------+-------+-------+
2 rows in set (0.00 sec)

mysql> SELECT * FROM student LIMIT 2,3;
+------+---------------+-------+-------+
| s_id | s_name        | s_sex | s_age |
+------+---------------+-------+-------+
| 1003 | shiyanlou1003 | man   |    18 |
| 1004 | shiyanlou1005 | woman |    40 |
| 1005 | shiyanlou1005 | man   |    17 |
+------+---------------+-------+-------+
```

## 子查询

在上面的内容中，关于查询的语法已经足够复杂，虽然对于完整的内容来说还稍显不足，但是，为了不再增加该语句的复杂性，这里，我们不再给出语法结构，而是讲解示例。

子查询又被称为嵌套查询，如下示例：

我们要查询选修了课程的课程号 `c_id` 为 `1` 的学生的年龄：

1. 首先我们需要从选课表`sc` 中查询，选修课程号 `c_id` 为 `1` 的学生的学号：

```bash
mysql> SELECT s_id FROM sc WHERE c_id=1;
+------+
| s_id |
+------+
| 1001 |
| 1002 |
+------+
```

2. 接着我们可以使用获得的学生号去查询年龄字段，从而得到最终的结果:

```bash
mysql> SELECT s_id,s_age FROM student WHERE s_id IN (1001,1002);
+------+-------+
| s_id | s_age |
+------+-------+
| 1001 |    10 |
| 1002 |    20 |
+------+-------+
```

上面的查询过程分为两步，而使用子查询我们只需要一步，如下：

```bash
mysql> SELECT s_id,s_age FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=1);
+------+-------+
| s_id | s_age |
+------+-------+
| 1001 |    10 |
| 1002 |    20 |
+------+-------+
```

即将第一步的查询嵌入第二步的操作中，并且将第一步查询的结果用于第二步查询的判断条件中。

类似的操作还有很多，下面我给出一个使用子查询的例子，大家可以分析其代表的含义，并且考虑有没有更简单的实现方式:

```bash
SELECT  * FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=(SELECT c_id FROM course WHERE c_time=(SELECT max(c_time) FROM course)));
```
## PLSQL 

http://study.163.com/course/introduction.htm?courseId=1543006#/courseDetail?tab=1



## 总结

在本节内容中，我们简单介绍了 MySQL 数据库的安装，服务的启动，以及怎么连接到数据库和如何修改配置。