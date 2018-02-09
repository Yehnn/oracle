# PL/SQL

## 实验介绍

### 实验内容

本节实验主要是对 PL/SQL 的内容进行学习，主要会涉及到对变量、运算符、数据类型、流程控制和异常处理相关的知识点。

### 实验知识点

+  PL/SQL 简介

+ 变量的声明与使用

+ 运算符

+ 数据类型

+ 流程控制

+ 异常处理

## PL/SQL 简介

`PL/SQL` 是 Oracle 对 SQL 的过程化语言扩展，是一种便携式，高性能的事务处理语言。它有变量和流程控制等概念，将 SQL 的数据操作能力与过程语言的处理能力结合起来。（更多有关 PL/SQL 介绍可参考[官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/overview.html#GUID-17166AA4-14DC-48A6-BE92-3FC758DAA940) ）

## 语法结构

PL/SQL 的结构通常如下：

```plsql
DECLARE      --声明部分。例如定义常量，变量，引用的函数或过程等。
BEGIN        --执行部分。包含变量赋值，过程控制等。
EXCEPTION    --处理异常。包含错误处理语句。
END;         --结束部分。
/            /*添加这个斜杠来执行 PL/SQL 语句块。*/
```

> 上面 `--` 后面和 `/* */` 包围的内容都是注释。这是 PL/SQL 的两种注释方式。
>
> BEGIN ，END 就类似于其他编程语言的 `{...}`  。

## 预热

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

## 变量的声明与使用

### 变量的声明

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

### 使用 %TYPE 属性声明

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

### 使用 %ROWTYPE 属性声明

使用 `％ROWTYPE` 属性可以声明表示数据库表或视图的全部或部分行的记录。记录字段不会继承相应列的约束和初始值。

例：改写上面根据学生编号查询学生姓名的代码。

```plsql
DECLARE
  v_row student%ROWTYPE;
BEGIN
  SELECT * INTO v_row FROM student WHERE s_id=1001;
  DBMS_OUTPUT.put_line('1001 student is : ' || v_row.s_name || v_row.s_sex || v_row.s_age);
END;
/
```

> 直接将符合条件的记录都赋给 `v_row` ，然后使用 `v_row.字段名` 的方式，就可获得想要的值，很方便。 

输出结果如下：

```
1001 student is : shiyanlou1001man10
```

### 全局变量和内部变量

全局变量可以在内部语句块中访问，内部变量在语句块外面访问不到。如下示例：

```plsql
DECLARE
  v_a VARCHAR2(20) := 'this is global';    --全局变量
  v_b VARCHAR2(20) := 'this is second global';
BEGIN
  DECLARE
    v_a VARCHAR2(20) := 'this is inner';   --内部变量
  BEGIN
    DBMS_OUTPUT.put_line(v_a);
    DBMS_OUTPUT.put_line(v_b);
  END;
  DBMS_OUTPUT.put_line(v_a);
END;
/
```

上面程序包含在第一个 BEGIN END 中的语句块就是内部程序块。

运行结果：

```
this is inner
this is second global
this is global
```

## 运算符

PL/SQL 中的运算符和 SQL 中的运算符是通用的。

- 赋值运算符 `:=` 
- 连接运算符 `||`
- 算术运算符 `-` 减，`+` 加，`*` 乘，`/`  除
- 关系运算符
- 逻辑运算符

赋值，连接，算术运算符很简单，我们都在前面使用过了。下面直接讲关系运算符和逻辑运算符。

### 关系运算符

下面做一个简单分类。

| 分类      | 运算符                      | 说明                                     |
| ------- | ------------------------ | -------------------------------------- |
| 简单关系运算符 | >， <， >= ，<=， =， !=， <>  | 大于，小于，大于等于，小于等于，等于。`!=` 和 `<>` 都表示不等于。 |
| 判断空值    | `IS NULL` ，`IS NOT NULL` | 判断某列内容是否是 NULL                         |
| 范围查询    | `BETWEEN` 最小值 `AND` 最大值  | 在指定的最小值和最大值的范围内查找                      |
| 范围查询    | `IN`                     | 指定查询的范围                                |
| 模糊查询    | `LIKE`                   | 模糊查询                                   |

如下实例综合使用了某些关系运算符。

```plsql
DECLARE
  v_a NUMBER :=1;
  v_b NUMBER :=2;
  v_c NUMBER;
  v_d VARCHAR2(20);
BEGIN
  IF v_a<v_b THEN     --判断 v_a 是否小于 v_b
    DBMS_OUTPUT.put_line(v_a || ' < ' || v_b);
  END IF;
  IF v_c IS NULL THEN   --判断 v_c 是否为空
    DBMS_OUTPUT.put_line('v_c is null');
  END IF;
  IF v_b BETWEEN 1 AND 3 THEN    --判断 v_b 是否在 1 到 3 之间
    DBMS_OUTPUT.put_line('v_b is between 1 and 3');
  END IF;
  IF v_b IN(1,2,3) THEN      --判断 v_b 是否在 （1，2，3）里
    DBMS_OUTPUT.put_line('v_b is : ' || v_b);
  END IF;
  IF v_d LIKE 'shi%' THEN     --判断 v_d 是否是 shi 开头
    DBMS_OUTPUT.put_line(v_d);
  END IF;
END;
/
```

输出结果：

```
1 < 2
v_c is null
v_b is between 1 and 3
v_b is : 2
```

### 逻辑运算符

逻辑运算符 `AND` ，`OR` ，`NOT` 。下面是逻辑真值表。

| x       | y       | x AND y | x OR y  | NOT x   |
| ------- | ------- | ------- | ------- | ------- |
| `TRUE`  | `TRUE`  | `TRUE`  | `TRUE`  | `FALSE` |
| `TRUE`  | `FALSE` | `FALSE` | `TRUE`  | `FALSE` |
| `TRUE`  | `NULL`  | `NULL`  | `TRUE`  | `FALSE` |
| `FALSE` | `TRUE`  | `FALSE` | `TRUE`  | `TRUE`  |
| `FALSE` | `FALSE` | `FALSE` | `FALSE` | `TRUE`  |
| `FALSE` | `NULL`  | `FALSE` | `NULL`  | `TRUE`  |
| `NULL`  | `TRUE`  | `NULL`  | `TRUE`  | `NULL`  |
| `NULL`  | `FALSE` | `FALSE` | `NULL`  | `NULL`  |
| `NULL`  | `NULL`  | `NULL`  | `NULL`  | `NULL`  |

（此表来自于 [逻辑运算符-官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/plsql-language-fundamentals.html#GUID-9D19FEBB-A397-47F5-A4EC-D71B0DE91738) ）

如下实例综合使用了逻辑运算符：

```plsql
DECLARE
  v_b1 BOOLEAN := TRUE;
  v_b2 BOOLEAN := FALSE;
  v_b3 BOOLEAN := TRUE;
BEGIN
  IF v_b1 AND v_b3 THEN
    DBMS_OUTPUT.put_line('v_b1 AND v_b3 is true');
  END IF;
  IF NOT v_b2 THEN
    DBMS_OUTPUT.put_line('v_2 is false');
  END IF;
  IF v_b1 OR v_b2 THEN
    DBMS_OUTPUT.put_line('v_b1 OR v_b2 is true');
  END IF;
END;
/
```

输出结果：

```
v_b1 AND v_b3 is true
v_2 is false
v_b1 OR v_b2 is true
```

## 数据类型

每个 PL/SQL 常数，变量，参数，和函数的返回值都具有数据类型，以确定其存储格式以及有效的值和操作。

Oracle 中提供的数据类型有四种：

- 标量类型（scala data type）：用来保存单个值。例如：数字，字符串，布尔值，日期等。
- 复合类型（coposite data type）：保存多种类型数值。例如：索引表，可变数组，嵌套表等。
- 引用类型（reference data type）：用来指向另一个不同的对象。
- LOB 类型：大数据类型，主要用来处理二进制数据，最多可以存储 4G 的信息。

上面只是介绍了数据类型的种类，而我们常用的是标量类型。主要学习标量类型。

**注意：PL/SQL 数据类型包括 SQL 数据类型。丹它们的最大尺寸有所不同。可参见** [PL/SQL 数据类型-官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/plsql-data-types.html#GUID-239A89A6-4CBC-46F5-8A6A-10E8B465B7E8) 。

### 数值类型

- `NUMBER`
- `BINARY_INTEGER` ，`PLS_INTEGER`
- `BINARY_DOUBLE` ，`BINARY_FLOAT` 

#### BINARY_INTEGER ，PLS_INTEGER

`BINARY_INTEGER` 和 `PLS_INTEGER` 对比 `NUMBER` ：

- 需要的存储空间更少。
- 性能更高：因为 `NUMBER` 以十进制存储，计算的时候会先转换成二进制。而 `BINARY_INTEGER` 和 `PLS_INTEGER` 以二进制的补码存储。

`BINARY_INTEGER` 和 `PLS_INTEGER` 是相同的。当操作的数值超出定义的范围会抛出异常。如下示例：

```plsql
DECLARE
  p1 PLS_INTEGER := 2147483647;
  p2 PLS_INTEGER := 1;
  n NUMBER;
BEGIN
  n := p1 + p2;
END;
/
```

两数想加的结果为 `2147483648` 超出了 `PLS_INTEGER` 的范围 `-2147483648~2147483647 的整数` 。即使我们把结果给了 `NUMBER` 类型，但仍然会抛出`数字溢出`的异常。 

将 p2 声明为 `INTEGER` 类型可以正确计算出结果：

```plsql
DECLARE
  p1 PLS_INTEGER := 2147483647;
  p2 INTEGER := 1;
  n NUMBER;
BEGIN
  n := p1 + p2;
END;
/
```

#### BINARY_FLOAT，BINARY_DOUBLE

同样 `BINARY_FLOAT`，`BINARY_DOUBLE`  的计算性能比 `NUMBER` 更高。前者是单精度类型，后者是双精度类型。主要用于科学计算。

下面示例输出这两种类型的值。

```plsql
DECLARE
  v_float BINARY_FLOAT := 6666.66F;
  v_double BINARY_DOUBLE :=6666.66F;
BEGIN
  DBMS_OUTPUT.put_line(v_float);
  DBMS_OUTPUT.put_line(v_double);
END;
/
```

输出结果如下：

```
6.66666016E+003
6.66666015625E+003
```

> 它是用科学记数法的方式存储的。

Oracle 中预定义了一些 `BINARY_FLOAT` 和 `BINARY_DOUBLE` 常量，比如无穷大，最小绝对数等等。可参见 [表3-2 预定义常量-官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/plsql-data-types.html#GUID-9410B67C-0E65-45BE-9376-0BD97E39D678) 。

例如输出 `BINARY_FLOAT` 最大值，最小值：

```plsql
BEGIN
  DBMS_OUTPUT.put_line('BINARY_FLOAT_MIN_NORMAL = ' || BINARY_FLOAT_MIN_NORMAL);
  DBMS_OUTPUT.put_line('BINARY_FLOAT_MAX_NORMAL = ' || BINARY_FLOAT_MAX_NORMAL);
END;
/
```

输出结果：

```
BINARY_FLOAT_MIN_NORMAL = 1.17549435E-038
BINARY_FLOAT_MAX_NORMAL = 3.40282347E+038
```

### 字符型

- `CHAR` 与 `VARCHAR2` 
- `NCHAR` 与 `NVARCHAR2`
- `LONG` 与 `LONG RAW` 
- `ROWID` 与 `UROWID`

#### CHAR 与 VARCHAR2 

- `CHAR` 以定长方式保存字符串。若赋值长度不足其定义长度，会以空格补充。
- `VARCHAR2` 变长字符串。若不足定义长度，不会补充内容。

如下实例说明了上述区别。

```plsql
DECLARE
  v_char CHAR(5);
  v_varchar2 VARCHAR2(5);
BEGIN
  v_char := 'SYL';
  v_varchar2 := 'SYL';
  DBMS_OUTPUT.put_line(v_char || ' length: ' || LENGTH(v_char));
  DBMS_OUTPUT.put_line(v_varchar2 || ' length: ' || LENGTH(v_varchar2));
END;
/
```

输出结果：

```
SYL   length: 5
SYL length: 3
```

#### NCHAR 与 NVARCHAR2

- 两者的区别与 CHAR 和  VARCHAR2 的区别相同。
- 保存的数据为 `UNICODE` 编码。

也就是说中文是占一位的。比如我们定义的是 `CHAR(3)` ，给它赋值为实验楼会报错，因为一个中文占两位。而定义为 `NCHAR(3)` ，则不会报错。

#### LONG 与 LONG RAW 

- LONG 保存变长字符串。
- LONG RAW 保存变长二进制数据。

用如下实例说明上述区别：

```plsql
DECLARE
  v_long LONG;
  v_longraw LONG RAW;
BEGIN
  v_long := 'SYL';
  v_longraw := UTL_RAW.cast_to_raw('SYL');    --转换为二进制
  DBMS_OUTPUT.put_line(v_long || ' length: ' || LENGTH(v_long)); 
  DBMS_OUTPUT.put_line(v_longraw || ' length: ' || LENGTH(v_longraw));   
  DBMS_OUTPUT.put_line(UTL_RAW.cast_to_varchar2(v_longraw) || ' length: ' || LENGTH(v_longraw));  --转换为 varchar2
END;
/
```

> `UTL_RAW.cast_to_raw` 和 `UTL_RAW.cast_to_varchar2` 是字符转换。

输出结果：

```
SYL length: 3
53594C length: 6
SYL length: 6
```

#### ROWID 与 UROWID

- ROWID 表示一条数据的物理行地址。
- UROWID 除了表示物理行地址，还增加了逻辑行地址。

如下实例输出学生编号为 `1001` 的那条记录的 `ROWID` 和 `UROWID` 。

```plsql
DECLARE
  v_rowid ROWID;
  v_urowid UROWID;
BEGIN
  SELECT ROWID INTO v_rowid FROM student WHERE s_id=1001;
  SELECT ROWID INTO v_urowid FROM student WHERE s_id=1001;
  DBMS_OUTPUT.put_line('v_rowid = '||v_rowid || '  v_urowid = '||v_urowid);
END;
/
```

 输出结果如下：

```
v_rowid = AAAR9rAABAAAZAJAAA  v_urowid = AAAR9rAABAAAZAJAAA
```

### 日期型

- DATE
- TIMESTAMP
- INTERVAL

#### DATE

DATE 类型用于存储日期和时间。

范围：公元前 4712 年 1 月 1 日到公元后 9999 年 12 月 31 日

占据空间：7 字节

形式类似于 `2017-1-1 06:06:06`  。

可以设置其日期和时间的表示格式，由 `NLS_DATE_FORMAT` 和 `NLS_DATE_LANGUAGE` 这两个初始参数控制。

如下实例输出当前系统时间。

```plsql
DECLARE
  v_d1 DATE := SYSDATE;
  v_d2 DATE := SYSTIMESTAMP;
BEGIN
  DBMS_OUTPUT.put_line(TO_CHAR(v_d1,'yyyy-mm-dd hh12:mi:ss'));
  DBMS_OUTPUT.put_line(TO_CHAR(v_d1,'yyyy-mm-dd hh24:mi:ss'));
  DBMS_OUTPUT.put_line(SYSDATE);
  DBMS_OUTPUT.put_line(SYSTIMESTAMP);
END;
/
```

输出结果：

```
2018-01-27 05:17:13
2018-01-27 17:17:13
27-1月 -18
27-1月 -18 05.17.13.447000000 下午 +08:00
```

如下实例设置初始参数来设置日期和时间。

1. 查看当前会话的 NLS 的初始参数设置：

```sql
select * from nls_session_parameters;
```

1. 查看 `NLS_DATE_FORMAT` 和 `NLS_DATE_LANGUAGE`初始参数设置：

```plsql
SHOW PARAMETER NLS_DATE_LANGUAGE;
SHOW PARAMETER NLS_DATE_FORMAT;
```

输出结果：

```
NAME              TYPE   VALUE              
----------------- ------ ------------------ 
nls_date_language string SIMPLIFIED CHINESE 
NAME            TYPE   VALUE     
--------------- ------ --------- 
nls_date_format string DD-MON-RR 
```

1. 设置初始参数

```plsql
ALTER SESSION SET NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss';
SELECT SYSDATE FROM DUAL;
```

输出结果：

```
2018-01-27 17:46:12
```

> 想要设置数据库系统的日期，时间格式，用 `ALTER SYSTEM` 。

#### TIMESTAMP

`TIMESTMP` 表示的时间更精确。用 `TIMESTMP` 声明的变量要用  `SYSTIMESTMP` 赋值。

`TIMESTAMP` 有两个扩展的子类型：

- `TIME ZONE` ：包含与格林威治时间的偏移量。
- `LOCAL TIME ZONE`：使用当前数据库的时区。

例：将两种类型的值分别输出，以观察它们的区别。

```plsql
DECLARE
  v_timezone TIMESTAMP WITH TIME ZONE := SYSTIMESTAMP;
  v_localtime TIMESTAMP WITH LOCAL TIME ZONE := SYSTIMESTAMP;
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_timezone);
  DBMS_OUTPUT.PUT_LINE(v_localtime);
END;
/
```

输出结果：

```
01-2月 -18 05.57.06.444000 下午 +08:00
01-2月 -18 05.57.06.444000 下午
```

#### INTERVAL

用来表示两个时间戳之间的时间间隔。它有两种子类型：

- `INTERVAL YEAR[(年的精度)] TO MONTHS` ：默认年的精度为 2
- `INTERVAL DAY[(天的精度)] TO SECOND[(秒的精度)]`  ：默认天的精度为 2，秒的精度为 6 

例一：计算五年零一个月后的日期和时间。

```plsql
DECLARE
  v_interval INTERVAL YEAR(3) TO MONTH := INTERVAL '5-1' YEAR TO MONTH;
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_interval);   --输出时间间隔
  DBMS_OUTPUT.PUT_LINE(v_interval+SYSDATE);  --输出计算后的日期和时间
END;
/
```

输出结果：

```
+005-01
2023-03-01 18:22:38
```

例二：计算 5 天 11 小时 11 分钟 11.1111 秒后的日期和时间。

```plsql
DECLARE
  v_interval2 INTERVAL DAY(3) TO SECOND := INTERVAL '5 11:11:11.1111' DAY TO SECOND;
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_interval2);
  DBMS_OUTPUT.PUT_LINE(v_interval2+SYSDATE);
END;
/
```

输出结果：

```
+005 11:11:11.111100
2018-02-07 05:33:49
```

### 布尔型

用 `BOOLEAN` 表示， 主要用于逻辑判断，可以存储 `TRUE` ，`FALSE`，`NULL`。之前已经使用过了。不做过多介绍。

### 子类型

子类型是基于标量类型的，相当于是一个类型的别名，使之简单化。子类型的创建语法如下：

```plsql
SUBTYPE 子类型名称 IS 父类型名称[(约束)] [NOT NULL]
```

例：创建一个子类型并使用。

```plsql
DECLARE
  SUBTYPE name_subtype IS VARCHAR2(20) NOT NULL;  --定义子类型
  v_name name_subtype := 'syl';  --使用子类型
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_name);
END;
/
```

输出结果：

```
syl
```

## 流程控制

### 条件语句

#### IF 语句

如果满足某种条件，就执行某种操作。IF 语句有如下几种形式

- `IF ...THEN...`
- `IF ... THEN ... ELSE ...`
- `IF ... THEN ... ELSIF ...` 

例：实现判断编号为 `1003` 这个学生的平均成绩是否大于 60，如果大于 60 则输出 pass ，如果大于 30 小于 60 则输出 lost ，如果小于 30 则输出 fail 。

```plsql
DECLARE
  v_grade sc.grade%TYPE;
BEGIN
  SELECT AVG(grade) INTO v_grade FROM student s JOIN sc USING(s_id) GROUP BY s_id HAVING s_id=1003;
  IF v_grade >= 60 THEN
    DBMS_OUTPUT.put_line('pass '||v_grade);
  ELSIF v_grade>=30 AND v_grade<60 THEN
    DBMS_OUTPUT.put_line('loss '||v_grade);
  ELSE
    DBMS_OUTPUT.put_line('fail '||v_grade);
  END IF;
END;
/
```

输出结果：

```
pass 75
```

#### CASE 语句

多条件判断。语法如下：

```plsql
CASE selector
	WHEN selector_value THEN statements_1;
	...
END CASE
```

例：判断编号为 `1003` 的学生性别，如果为 `man` 就输出学生姓名和性别。

```plsql
DECLARE
  v_name student.s_name%TYPE;
  v_sex student.s_sex%TYPE;
BEGIN
  SELECT s_name,s_sex INTO v_name,v_sex FROM student WHERE s_id=1003;
  CASE v_sex
    WHEN 'man' THEN 
      DBMS_OUTPUT.put_line(v_name|| ' is man');
    WHEN 'woman' THEN
      DBMS_OUTPUT.put_line(v_name ||'is woman');
    ELSE
      DBMS_OUTPUT.put_line('dont know');
    END CASE;
END;
/
```

输出结果：

```
shiyanlou1003 is man
```

### 循环语句

#### WHILE 循环

语法：

```plsql
WHILE （循环结束条件）LOOP
	循环执行的语句块;
END LOOP;
```

例：输出1，2，5 。

```plsql
DECLARE
  v_i NUMBER := 1;
BEGIN
  WHILE(v_i <= 5) LOOP   --当 v_i <=3 时
    DBMS_OUTPUT.put_line(v_i);
    v_i := v_i+1;    --v_i 加1
  END LOOP;
END;
/
```

还可以使用如下语句实现相同效果。

```plsql
DECLARE
  v_i NUMBER := 1;
BEGIN
  LOOP
    DBMS_OUTPUT.put_line(v_i);
    EXIT WHEN v_i>=5;   --当 v_i>=3 时退出循环
    v_i := v_i+1;
  END LOOP;
END;
/
```

#### FOR 循环

语法：

```plsql
FOR 循环索引 IN [REVERSE] 循环区域下限 循环区域上限 LOOP
	循环执行的语句块;
END LOOP;
```

例：用 FOR 实现循环输出 1 到 5 。

```plsql
DECLARE
  v_i NUMBER :=1;
BEGIN
  FOR v_i IN 1 .. 5 LOOP
    DBMS_OUTPUT.put_line(v_i);
  END LOOP;
END;
/
```

### 循环控制

#### EXIT

`EXIT` 会直接退出循环。

```plsql
DECLARE
  v_i NUMBER :=1;
BEGIN
  FOR v_i IN 1 .. 5 LOOP
    IF v_i = 3 THEN
      EXIT;
    END IF;
    DBMS_OUTPUT.put_line(v_i);
  END LOOP;
END;
/
```

输出结果：

```plsql
1
2
```

#### CONTINUE

`CONTINUE` 退出当前语句块。

```plsql
DECLARE
  v_i NUMBER :=1;
BEGIN
  FOR v_i IN 1 .. 5 LOOP
    IF v_i = 3 THEN
      CONTINUE;
    END IF;
    DBMS_OUTPUT.put_line(v_i);
  END LOOP;
END;
/
```

输出结果：

```
1
2
4
5
```

#### GOTO

无条件跳转到某个地方。不建议使用。

```plsql
DECLARE
  v_i NUMBER :=1;
BEGIN
  FOR v_i IN 1 .. 5 LOOP
    IF v_i = 3 THEN
      GOTO flag;      --GOTO 跳转
    END IF;
    DBMS_OUTPUT.put_line(v_i);
  END LOOP;
  <<flag>>          --定义了要跳转的地方。
  DBMS_OUTPUT.put_line('goto');
END;
/
```

输出结果：

```
1
2
goto
```

## 异常处理

当出现异常时，程序会中断执行，如果我们写了异常处理，程序将会捕获异常，在捕获到异常后抛出异常，程序继续执行。

语法：

```plsql
EXCEPTION
	WHEN 异常类型 | 用户自定义异常 | 异常代码 | OTHERS THEN
		异常处理语句;
```

### 使用预定义的异常

例一：捕获除数为 0 的异常。

```plsql
DECLARE
  v_a NUMBER := 1;
  v_b NUMBER := 0;
BEGIN
  v_a := v_a/v_b;
EXCEPTION
  WHEN ZERO_DIVIDE THEN   --捕获除数为 0 的异常
    DBMS_OUTPUT.put_line('zero divide');
    DBMS_OUTPUT.put_line(SQLCODE);  --输出异常编号
    DBMS_OUTPUT.put_line(SQLERRM);  --输出异常详情
END;
/
```

> 上面的 `ZERO_DIVIDE` 是捕获除数为 0 的异常。这是 Oracle 中预定义的异常名，可以直接使用，还有很多的预定义异常，可参考 [表11-3 预定义的异常-官方文档](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/lnpls/plsql-error-handling.html#GUID-8C327B4A-71FA-4CFB-8BC9-4550A23734D6) 。

输出结果：

```
zero divide
-1476
ORA-01476: 除数为 0
```

例二：从键盘输入学生编号，查询出对应的学生姓名。当我们输入的学生编号在表中不存在时抛出异常。

```plsql
DECLARE
  v_sid NUMBER;            --接收学生编号
  v_sname VARCHAR2(20);    --接收学生姓名
BEGIN
  v_sid := &studentid;     --键盘输入数据
  SELECT s_name INTO v_sname FROM student WHERE s_id=v_sid; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
EXCEPTION
  WHEN no_data_found THEN    --捕获不存在的异常
    DBMS_OUTPUT.put_line('not found the student');
END;
/
```

当输入 `1006` 的时候会抛出此异常。

例三：捕获返回行数过多的异常。比如我们在这里查询年龄大于 10 岁的学生，会返回多个记录。

```plsql
DECLARE
  v_sname VARCHAR2(20);    --接收学生姓名
BEGIN
  SELECT s_name INTO v_sname FROM student WHERE s_age>10; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
EXCEPTION
  WHEN TOO_MANY_ROWS THEN    --抛出返回行数过多的异常
    DBMS_OUTPUT.put_line('too many rows');
END;
/
```

输出结果：

```
too many rows
```

这么多的异常名我们可能很难全部记住，在处理异常的时候可以使用 `OTHERS` 替代。比如上面的程序我们可以这样写。

```plsql
DECLARE
  v_sname VARCHAR2(20);    --接收学生姓名
BEGIN
  SELECT s_name INTO v_sname FROM student WHERE s_age>10; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
EXCEPTION
  WHEN OTHERS THEN     --使用 OTHERS 捕获
    DBMS_OUTPUT.put_line(SQLCODE || ':' || SQLERRM);
END;
/
```

上面都是使用的 Oracle 已经定义好的异常名，除此之外，我们仍可以**自定义异常** 。

### 自定义异常

#### 声明异常

```plsql
DECLARE
  v_a NUMBER := 1;
  v_exception EXCEPTION;  --声明异常
BEGIN
  IF v_a = 1 THEN
    RAISE v_exception;  --抛出异常
  END IF;
EXCEPTION 
  WHEN v_exception THEN   --捕获异常
    DBMS_OUTPUT.put_line('exception:is 1');
    DBMS_OUTPUT.put_line(SQLCODE);
    DBMS_OUTPUT.put_line(SQLERRM);
END;
/
```

> 上面的异常捕获也可以使用 `WHEN OTHERS THEN` 。使用 `OTHERS` 虽然方便，但是会捕获所有的异常一起处理，不能分开处理。

输出结果：

```
PL/SQL 过程已成功完成。
exception:is 1
1
User-Defined Exception
```

#### 定义异常编码

上面的 `SQLCODE` 是 1，我们是可以自定义这个 `SQLCODE` 的。如下示例自定义 `SQLCODE` 为 -6666 。（定义的编码可以是已经有的编码）

**注意：**定义的编码必须要范围在 `-20000~-20999` 。

```plsql
DECLARE
  v_a NUMBER := 1;
  v_exception EXCEPTION;  --声明异常
  PRAGMA EXCEPTION_INIT(v_exception,-20666);   --自定义异常代码
BEGIN
  IF v_a = 1 THEN
    RAISE v_exception;  --抛出异常
  END IF;
EXCEPTION 
  WHEN v_exception THEN   --捕获异常
    DBMS_OUTPUT.put_line('exception:is 1');
    DBMS_OUTPUT.put_line(SQLCODE);
    DBMS_OUTPUT.put_line(SQLERRM);
END;
/
```

输出结果：

```
exception:is 1
-6666
ORA-06666: 
```

#### 动态构建异常

直接在程序块中使用 `RAISE_APPLICATION_ERROR` 抛出对应异常。

```plsql
DECLARE
  v_a NUMBER := 1;
  v_exception EXCEPTION;  --声明异常
  PRAGMA EXCEPTION_INIT(v_exception,-20666);
BEGIN
  IF v_a = 1 THEN
    RAISE_APPLICATION_ERROR(-20666,'raise application error');  --抛出异常。此编码一定要和定义的编码一样。
  END IF;
EXCEPTION 
  WHEN v_exception THEN   --捕获异常。此名字一定要和声明的异常名一样。
    DBMS_OUTPUT.put_line(SQLCODE);
    DBMS_OUTPUT.put_line(SQLERRM);
END;
/
```

输出结果：

```
PL/SQL 过程已成功完成。
-20666
ORA-20666: raise application error
```

上面的程序实际上可以简化成下面这样，只使用一个 `RAISE_APPLICATION_ERROR` ，然后用 	`OTHERS` 捕获，省去了声明异常以及设置编号。

```plsql
DECLARE
  v_a NUMBER := 1;
  --v_exception EXCEPTION;  --声明异常
  --PRAGMA EXCEPTION_INIT(v_exception,-20666);
BEGIN
  IF v_a = 1 THEN
    RAISE_APPLICATION_ERROR(-20666,'raise application error');  --抛出异常
  END IF;
EXCEPTION 
  WHEN OTHERS THEN   --捕获异常
    DBMS_OUTPUT.put_line(SQLCODE);
    DBMS_OUTPUT.put_line(SQLERRM);
END;
/
```

## 总结

