# I/O优化

## 实验介绍

### 实验内容



### 实验知识点

+ ​




## 数据文件 I/O 监控

I/O 优化的目标就是减少物理 I/O （磁盘上的 I/O 活动）的发生，因为逻辑 I/O（内存中的 I/O 活动） 比物理 I/O 快得多。虽然在之前的内存优化中，能减少物理 I/O，但是还有一些其他影响 I/O  的因素。

### 查看数据文件 I/O 情况

使用 `v$filestat` 和 `v$datafile` 视图可以查看数据文件的 I/O 情况：

```sql
SQL> select name,phyrds,phywrts,readtim,writetim from v$filestat a join v$datafile b using(file#) order by readtim desc;

NAME                                        PHYRDS    PHYWRTS   READTIM    WRITETIM
---------------------------------------- ---------- ---------- ---------- ----------
/u01/app/oracle/oradata/xe/system01.dbf        7702      11     1761          15
/u01/app/oracle/oradata/xe/sysaux01.dbf        2786     2188     231         233
/u01/app/oracle/oradata/xe/undotbs01.dbf       3239    4825       12         189
/u01/app/oracle/oradata/xe/users01.dbf           1        0        0           0
```

> `PHYRDS` 和 `PHYWRTS` 分别代表物理读取和写入次数。
>
> `READTIM` 和 `WRITETIM` 分别代表读取和写入花费的时间。
>
> 针对一些经常使用的数据文件，我们可以把它移动到负载较小的磁盘上，以实现磁盘负载均衡。

### 查看临时数据文件 I/O 情况

如果想要查看临时数据文件的 I/O 情况，可以使用 `v$tempfile` ：

```sql
SQL> select name,phyrds,phywrts,readtim,writetim from v$filestat a,v$tempfile b where a.file#=b.file# order by readtim desc;

NAME                                        PHYRDS    PHYWRTS  READTIM   WRITETIM
---------------------------------------- ---------- ---------- ---------- ----------
/u01/app/oracle/oradata/xe/temp01.dbf       7759          11     1768         15
```

### 查看数据文件剩余空间

检测数据文件剩余空间：

```sql
SQL> select file_name,total_size,used_size,total_size-used_size free_size,round((total_size-used_size)/total_size*100,2) "free ratio(%)" from (select file_id,file_name,bytes/1024/1024 total_size from dba_data_files) t,(select file_id,sum(bytes)/1024/1024 used_size from dba_free_space group by file_id) u where t.file_id=u.file_id order by "free ratio(%)" desc;

FILE_NAME                                TOTAL_SIZE  USED_SIZE  FREE_SIZE free ratio(%)
---------------------------------------- ---------- ---------- ---------- -------------
/u01/app/oracle/oradata/xe/undotbs01.dbf       260        1        259       99.62
/u01/app/oracle/oradata/xe/system01.dbf        790      7.9375    782.0625     99
/u01/app/oracle/oradata/xe/sysaux01.dbf        800      39.4375   760.5625    95.07
/u01/app/oracle/oradata/xe/users01.dbf          5        3.25       1.75       35
```

### 查看数据文件读写重载率

```sql
SQL> select round((select count(*) from v$filestat where phyrds>=(select avg(phyrds) from v$filestat))/(select count(*) from v$datafile)*100) "reads ratio(%)" from dual;

READS RATIO(%)
-----------
 25

SQL> select round((select count(*) from v$filestat where phywrts>=(select avg(phywrts) from v$filestat))/(select count(*) from v$datafile)*100) "writs ratio(%)" from dual;

WRITS RATIO(%)
-----------
 50
```








## 总结

