# SQL 与 PL/SQL

## 实验介绍

### 实验内容



### 实验知识点

+ 数据库简介
+ SQL 简介
+ 安装 MySQL

## SQL 和 PL/SQL 简介

`SQL` 是 `Structured Query Language` 的首字母缩写，意为结构化查询语言，它可以告诉 Oracle 对哪些信息进行选择，插入，更新和删除。相信大家已经很熟悉，在 mysql 和 sqlserver 中我们也经常使用。

`PL/SQL` 是 Oracle 对 SQL 的过程化语言扩展，是一种便携式，高性能的事务处理语言。它有变量和流程控制等概念，将 SQL 的数据操作能力与过程语言的处理能力结合起来。（更多有关 PL/SQL 介绍可参考[官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/overview.html#GUID-17166AA4-14DC-48A6-BE92-3FC758DAA940) ）

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

### 简单查询


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

```sql
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

#### MAX，MIN

查找列的最大值和最小值。例如查找学生表中的年龄的最大值和最小值：

```sql
SQL> SELECT max(s_age),min(s_age) FROM student;

MAX(S_AGE) MIN(S_AGE)
---------- ----------
        40         10
```

#### SUM，AVG

`SUM` 和 `AVG` 分别可以用来求和以及求平均值。

例如，查找选课表中，`s_id=1001` 学生成绩的总分及平均值：

```sql
SQL> SELECT avg(grade),sum(grade) FROM sc WHERE s_id='1001';

AVG(GRADE) SUM(GRADE)
---------- ----------
        62        186
```

除此之外，我们还可以使用 `DISTINCT` 修饰符指定从结果集中删除重复的行，对应的是 `ALL` ，为默认项。通过如下示例来了解：

```sql
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

```sql
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

```sql
SQL> SELECT CONCAT(CONCAT(s_name,'''s sex is '),s_sex) "sex" FROM student WHERE s_id=1001;
sex
-------------------------------------------------------------------
shiyanlou1001's sex is man
```

想了解更多有关函数的内容可以参考 [SQL 函数](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sqlrf/COUNT.html#GUID-AEF08B79-024D-4E3A-B362-9715FB011776)

### 分组排序

关于分组我们会学习到 `SELECT` 的两个子句，分别为：

- `GROUP BY`
- `HAVING`

详细的语法格式对于初学者来说并不友好，下面我们通过实例来讲解相关的内容。

#### GROUP BY

分组(`GROUP BY`) 功能，有时也称聚合，一些函数可以对分组数据进行操作，例如我们上述所列的 `AVG` `SUM` 都有相关的功能，不过我们并未使用分组，所以默认使用所有的数据进行操作。

我们可以选择上面的一种进行分组，也可以重复多个，或者综合使用。

例一：我们根据字段名 `s_id` 进行分组并计数：

```sql
SQL> SELECT s_id,count(*) FROM sc GROUP BY s_id;

      S_ID   COUNT(*)
---------- ----------
      1001          3
      1002          3
      1003          1
```

例二：根据 `s_id` 进行分组后查询学生的总成绩，使用 `SUM` 函数：

```sql
SQL> SELECT s_id,sum(grade) FROM sc GROUP BY s_id;

      S_ID SUM(GRADE)
---------- ----------
      1003         75
      1001        186
      1002        260
```

另外我们可以使用多个列进行分组。下面我们使用 `s_id` 以及 `grade` 进行分组。

```sql
SQL> SELECT s_id,grade, sum(grade) FROM sc GROUP BY s_id,grade;

      S_ID      GRADE SUM(GRADE)
---------- ---------- ----------
      1002        100        100
      1003         75         75
      1001         70         70
      1001         96         96
      1002         80        160
      1001         20         20

已选择 6 行。
```

#### HAVING

除了可以对数据进行分组之外，我们还可以使用 `HAVING` 对分组数据进行过滤。

例如：从选课表中筛选出选课总成绩大于 `100` 分的学生。

```sql
SQL> SELECT s_id, sum(grade) FROM sc GROUP BY s_id HAVING sum(grade)>100;

      S_ID SUM(GRADE)
---------- ----------
      1001        186
      1002        260
```

#### ORDER BY

`ORDER BY` 用于对数据进行排序。

下面我们举一个综合示例：将选课表 `sc` 的数据根据 `s_id` 进行分组，并计算每组总成绩，然后筛选出 `总成绩>100` 的分组，输出结果根据总成绩进行降序排列。

```sql
SQL> SELECT s_id,sum(grade) AS sum_grade FROM sc GROUP BY s_id HAVING sum(grade)>100 ORDER BY sum(grade) DESC;

      S_ID  SUM_GRADE
---------- ----------
      1002        260
      1001        186
```

> `AS` 是命别名的意思，可以省略。
>
> `DESC` 代表降序排列。省略的话则是升序排列。 

### 限制返回的行数

`ROWNUM` 用来限制查询返回的行数，这是一个伪列，给结果集的每一行编了一个顺序号。和 `mysql` 中的 `limit` 作用类似。

例：查询 `student` 表中的前两行。

```sql
SQL> SELECT * FROM student where rownum<3;

      S_ID S_NAME               S_SEX                     S_AGE
---------- -------------------- -------------------- ----------
      1001 shiyanlou1001        man                          10
      1002 shiyanlou1002        woman                        20
```

> 注意：并不能使用使用类似如下两种语句：
>
> ```sql
> select * from student where rownum>2;
> select * from student where rownum>2 and rownum<5;
> ```

### 子查询

子查询又被称为**嵌套查询**，如下示例：

我们要查询选修了课程的课程号 `c_id` 为 `1` 的学生的年龄：

1. 首先我们需要从选课表`sc` 中查询，选修课程号 `c_id` 为 `1` 的学生的学号：

```sql
SQL> SELECT s_id FROM sc WHERE c_id=1;

      S_ID
----------
      1001
      1002
```

2. 接着我们可以使用获得的学生号去查询年龄字段，从而得到最终的结果:

```sql
SQL> SELECT s_id,s_age FROM student WHERE s_id IN (1001,1002);

      S_ID      S_AGE
---------- ----------
      1001         10
      1002         20
```

上面的查询过程分为两步，而使用子查询我们只需要一步，如下：

```sql
SQL> SELECT s_id,s_age FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=1);

      S_ID      S_AGE
---------- ----------
      1001         10
      1002         20
```

即将第一步的查询嵌入第二步的操作中，并且将第一步查询的结果用于第二步查询的判断条件中。

类似的操作还有很多，下面给出一个使用子查询的例子，大家可以分析其代表的含义，并且考虑有没有更简单的实现方式：

```sql
SELECT  * FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=(SELECT c_id FROM course WHERE c_time=(SELECT max(c_time) FROM course)));
```
### 表的连接

表的连接主要用于多表查询，我们先来看将所有示例表存储在一张表中会是什么样子。

| 学号   | 课程号  | 学生姓名         | 学生年龄 | 学生性别 | 课程名   | 课时   | 成绩   |
| ---- | ---- | ------------ | ---- | ---- | ----- | ---- | ---- |
| 1001 | 3    | shiyanlou001 | 10   | man  | c     | 10   | 70   |
| 1001 | 1    | shiyanlou001 | 10   | man  | java  | 13   | 20   |
| 1001 | 2    | shiyanlou001 | 4    | man  | spark | 15   | 90   |
| ...  | ...  | ...          | ...  | ...  | ...   | ...  |      |

大致如上所示，这里我只给出了简单的几条数据，对比将选课的信息，划分为三张表进行存储，我们不用存储更多重复的信息，明显后者要高效的多。

**表的连接基于关系表，可以用来关联多个表。**

我们可以使用语句实现这个三表关联的操作：

```sql
SQL> SELECT sc.s_id,sc.c_id,s_name,c_name,grade,s_age,s_sex,c_time FROM student,course,sc WHERE student.s_id=sc.s_id AND course.c_id=sc.c_id;
```

> 执行过后的显示可能会有点乱，可以使用如下命令先调整显示格式，再执行
>
> ```sql
> SQL> col s_name for a20;
> SQL> col c_name for a15;
> SQL> set linesize 500;
> ```

让我们简化一些，只从每张表中列出其它表中关键的信息，如下所示，我们可以得到学生比较直观的选课信息：

```sql
SQL> SELECT sc.s_id, sc.c_id, s_name, c_name, grade FROM student, course, sc WHERE student.s_id=sc.s_id AND course.c_id=sc.c_id;

      S_ID       C_ID S_NAME          C_NAME          GRADE
---------- ---------- --------------- ---------- ----------
      1001          3 shiyanlou1001   c                  70
      1001          1 shiyanlou1001   java               20
      1001          4 shiyanlou1001   spark              96
      1002          1 shiyanlou1002   java              100
      1002          2 shiyanlou1002   python             80
      1002          4 shiyanlou1002   spark              80
      1003          3 shiyanlou1003   c                  75

已选择 7 行。
```
#### 笛卡尔积连接

**笛卡儿积连接**又叫**交叉连接** ，是多个表之间无条件的连接，它所查询出来的结果数量是每个表的记录数量的乘积，所以查询结果非常之大，在实际中要避免笛卡尔积连接。

下面对 `student` 表和 `course` 表进行笛卡尔积连接：

```sql
SQL> select * from student,sc;
或者
SQL> select * from student cross join sc;
-- 查询结果数量
SQL> select count(*) from student,sc;
```

从输出结果可以看到一共有 35 条记录，是两表记录数量的乘积。

我们可以对其指定连接条件来避免此种情况：

```sql
SQL> select * from student,sc where student.s_id=sc.s_id;
```

> 注意：积依然存在，只是不显示了。

#### 内连接

内连接（有时称为简单连接）是两个或多个表的连接，它们只返回满足连接条件的那些行。使用  `INNER JOIN .... ON` 。

例：将 `sc` 表和 `student` 表内连接：

```sql
SQL> SELECT sc.s_id, sc.c_id, s.s_name, sc.grade FROM sc INNER JOIN student s ON s.s_id=sc.s_id;

      S_ID       C_ID S_NAME               GRADE
---------- ---------- --------------- ----------
      1001          3 shiyanlou1001           70
      1001          1 shiyanlou1001           20
      1002          1 shiyanlou1002          100
      1001          4 shiyanlou1001           96
      1002          2 shiyanlou1002           80
      1003          3 shiyanlou1003           75
      1002          4 shiyanlou1002           80

已选择 7 行。
```

> `inner` 可省略。

也可以使用 `using` 来连接：

```sql
SQL> SELECT s_id, sc.c_id, s.s_name, sc.grade FROM sc JOIN student s using(s_id);
```

#### 外连接

外连接扩展了内连接的结果，将某个连接表中不符合连接条件的记录加入结果集中。外连接分为左外连接、右外连接、全外连接三种。

##### 左外连接

使用 `LEFT JOIN` 。会返回 `LEFT JOIN` 左边表查询的所有行，如果 `JOIN` 右边的表没有相匹配的行，会返回空。 

```sql
SQL> SELECT student.s_id,s_name,c_id,grade FROM student LEFT JOIN sc ON student.s_id=sc.s_id;

      S_ID S_NAME                C_ID      GRADE
---------- --------------- ---------- ----------
      1001 shiyanlou1001            3         70
      1001 shiyanlou1001            1         20
      1002 shiyanlou1002            1        100
      1001 shiyanlou1001            4         96
      1002 shiyanlou1002            2         80
      1003 shiyanlou1003            3         75
      1002 shiyanlou1002            4         80
      1004 shiyanlou1004
      1005 shiyanlou1005

已选择 9 行。
```

##### 右外连接

使用 `RIGHT JOIN` 。会返回 `RIGHT JOIN` 右边表查询的所有行，如果 `JOIN` 左边的表没有相匹配的行，会返回空。 

```sql
SQL> SELECT student.s_id,s_name,c_id,grade FROM student RIGHT JOIN sc ON student.s_id=sc.s_id;

      S_ID S_NAME                C_ID      GRADE
---------- --------------- ---------- ----------
      1001 shiyanlou1001            3         70
      1001 shiyanlou1001            1         20
      1001 shiyanlou1001            4         96
      1002 shiyanlou1002            1        100
      1002 shiyanlou1002            2         80
      1002 shiyanlou1002            4         80
      1003 shiyanlou1003            3         75

已选择 7 行。
```

##### 全外连接

使用 `FULL JOIN` ，会返回两表所有行，如果不满足连接条件，会返回空值。

```sql
SQL> SELECT student.s_id,s_name,c_id,grade FROM student FULL JOIN sc ON student.s_id=sc.s_id;

      S_ID S_NAME                C_ID      GRADE
---------- --------------- ---------- ----------
      1001 shiyanlou1001            3         70
      1001 shiyanlou1001            1         20
      1002 shiyanlou1002            1        100
      1001 shiyanlou1001            4         96
      1002 shiyanlou1002            2         80
      1003 shiyanlou1003            3         75
      1002 shiyanlou1002            4         80
      1004 shiyanlou1004
      1005 shiyanlou1005

已选择 9 行。
```

#### 自然连接

自然连接会自动根据两个表中相同数据类型，相同名称的列进行连接。使用 `NATURAL JOIN` 。

```sql
SQL> SELECT * FROM course NATURAL JOIN sc;

      C_ID C_NAME         C_TIME       S_ID      GRADE
---------- ---------- ---------- ---------- ----------
         3 c                  10       1001         70
         1 java               13       1001         20
         1 java               13       1002        100
         4 spark              15       1001         96
         2 python             12       1002         80
         3 c                  10       1003         75
         4 spark              15       1002         80

已选择 7 行。
```

和下面的内连接语句输出结果一样：

```sql
SQL> select * from course inner join sc on course.c_id=sc.c_id;
```

向了解更多有关表连接的内容可以参考 [表的连接](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sqlrf/Joins.html#GUID-39081984-8D38-4D64-A847-AA43F515D460)

### 视图

在上面的内容中，我们通过使用联结来获取相关的信息。如果我们需要经常使用上述查询的内容，可以通过定义视图来实现。

视图（View）是从一个或多个表（这里的表指基本表和视图）导出的表。为了区分视图和表，所以表有时又被称为“基本表”。

对于视图来说，数据库中只保存有视图的定义，而通过视图获得的数据，都来自与它相关的基本表，视图本身是没有数据的。因此，如果我们对视图的数据进行操作，其实也就是对基本表的数据进行操作，而这种操作也是有一定的限制。

#### 创建视图

创建视图使用 `CREATE VIEW` 。例如我们创建一个包含三张表内容的视图 `all_info` 。

```sql
SQL> CREATE VIEW all_info AS SELECT sc.s_id,sc.c_id,s_name,c_name,grade,s_age,s_sex,c_time FROM student,course,sc WHERE student.s_id=sc.s_id AND course.c_id=sc.c_id;
```

查看 `all_info` 视图结构以及内容：

```sql
SQL> desc all_info;
SQL> select * from all_info;
```

创建好了过后我们可以在数据字典 `user_views` 看到它：

```sql
SQL> select view_name from user_views where view_name='ALL_INFO';

VIEW_NAME
----------------------
ALL_INFO
```

想了解更多有关创建视图的内容可参考 [创建视图](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sqlrf/CREATE-VIEW.html#GUID-61D2D2B4-DACC-4C7C-89EB-7E50D9594D30)

创建好了这个视图过后，我们可以利用在表中查询数据的操作来对视图内容进行查询。例如查询视图中成绩大于 80 的学生：

```sql
SQL> select * from all_info where grade>80;
```

#### 删除视图

删除视图使用 `DROP VIEW` 。如下所示，删除视图 `all_info` 。

```sql
SQL> drop view all_info;
```

## PL/SQL 

http://study.163.com/course/introduction.htm?courseId=1543006#/courseDetail?tab=1 章节16

### 语法结构

PL/SQL 的结构通常如下：

```plsql
DECLARE      --声明部分。例如定义常量，变量，引用的函数或过程等。
BEGIN        --执行部分。包含变量赋值，过程控制等。
EXCEPTION    --处理异常。包含错误处理语句。
END;         --结束部分。
/            /*添加这个斜杠来执行 PL/SQL 语句块。*/
```

> 上面 `--` 后面和 `/* */` 包围的内容都是注释。这是 PL/SQL 的两种注释方式。

### 预热

我们先来做几个简单实践大致了解 PL/SQL。

例一：输出 `Hello World` 。为了方便，后文所述内容除使用 `$` 特别标识外，均在 `SQL` 命令行输入。

```plsql
SET SERVEROUTPUT ON;   --默认输出显示是关闭的，需要首先打开才会显示
BEGIN
  DBMS_OUTPUT.put_line('Hello World');
END;
/
```

输出结果如下：

```
PL/SQL 过程已成功完成。
Hello World
```

例二：声明一个变量并使用。该语句实现输出 `my name is : syl`  。

```plsql
DECLARE
  v_name varchar2(20); --定义变量
BEGIN
  v_name := 'syl';  --为变量赋值
  DBMS_OUTPUT.put_line('my name is : ' || v_name);
END;
/
```

> 注意：PL/SQL 中字符串连接用 `||` 。

例三：从键盘输入学生编号（比如输入 `1001` ），查询出对应的学生姓名。输出 `student's name is : shiyanlou1001` 。

```plsql
DECLARE
  v_sid NUMBER;            --接收学生编号
  v_sname VARCHAR2(20);    --接收学生姓名
BEGIN
  v_sid := &studentid;     --键盘输入数据
  SELECT s_name INTO v_sname FROM student WHERE s_id=v_sid; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
END;
/
```

经过上面的实践，相信大家已经对 PL/SQL 有了一个大概的了解。接下来我们正式进入详细的 PL/SQL 学习。

### 变量的声明与赋值



- 变量的声明与使用
- `%TYPE` 的使用
- `%ROWTYPE` 的使用

#### 变量的声明

声明为指定数据类型的值分配存储空间，并命名存储位置以便引用它。

必须先声明对象，然后才能引用它们。声明可以出现在任何块，子程序或包的声明部分。

（此段引用自 [PLSQL 声明-官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/plsql-language-fundamentals.html#GUID-65F9E0D0-03CD-4C40-829A-7392ACE8F932) ）

声明的语法：

```plsql
DECLARE
	变量名称 [CONSTANT] 类型 [NOT NULL] [:=value];
```

> - 变量名称必须遵守如下规定：
>   - 由`字母`，`数字`，`_`，`$` ，`#` 组成。
>   - 以字母开头，不能是 Oracle 中的关键字
>   - 变量的长度最多为 30 个字符。
> - `CONSTANT` 是声明常量。
> - `:=value` 是设置默认值。

例如：如下的变量名是不符合规定的。

```plsql
me&you
2user
on/off
student id
select
```

例一：声明一个名叫 `v_syl` 的变量。

```plsql
DECLARE
	v_syl VARCHAR2(20);
BEGIN
	NULL;
END;
/
```

例二：声明有默认值的变量。下列程序实现计算 v_a 和 v_b 的和。

```plsql
DECLARE
  v_a NUMBER :=1;
  v_b NUMBER; 
BEGIN
  v_B := 2;
  DBMS_OUTPUT.put_line(v_A+v_B);
END;
/
```

> 可以发现不区分大小写。

例三：声明一个不为空的变量。

```plsql
DECLARE
  v_sid NUMBER NOT NULL := 1;
BEGIN
  NULL;
END;
/
```

> 注意：声明不为空的话，一定要设置默认值。不然会报错 `PLS-00218: 声明为 NOT NULL 的变量必须有初始化赋值` 。

除了可以声明变量，还可以声明常量。常量的初始值是其永久值。如下示例声明了两个常量。

```plsql
DECLARE
  v_num CONSTANT NUMBER := 1;
  v_bool CONSTANT BOOLEAN := FALSE;
BEGIN
  NULL;
END;
/
```

#### 使用 %TYPE 属性声明

有时候我们想要声明与之前声明的变量或指定数据表中的某列相同数据类型的数据项，但是我们并不知道之前声明的变量的类型，这个时候就可以使用 `%TYPE` 。引用项目会继承如下内容：

- 数据类型和大小。
- 约束。

注意：

- 引用项目不会继承初始值。
- 如果被引用项目的声明发生变化，则引用项目的声明会相应地改变。

语法：

```
引用项目名称 被引用项目名称%TYPE;
```

例：我们改写之前根据学生编号查询学生姓名的代码。让变量 `v_sid` 和 `v_sname` 分别引用表 `student` 的 `s_id` 和 `s_name` 的数据类型。

```plsql
DECLARE
  v_sid student.s_id%TYPE;            --接收学生编号
  v_sname student.s_name%TYPE;    --接收学生姓名
BEGIN
  v_sid := &studentid;     --键盘输入数据
  SELECT s_name INTO v_sname FROM student WHERE s_id=v_sid; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
END;
/
```

输入学生编号 `1001` 依然可以查询出对应的姓名。

#### 使用 %ROWTYPE 属性声明











## 总结

在本节内容中，我们简单介绍了 MySQL 数据库的安装，服务的启动，以及怎么连接到数据库和如何修改配置。