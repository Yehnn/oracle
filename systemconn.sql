-- 查询默认表空间
select tablespace_name from dba_tablespaces;
-- 查询用户默认表空间
select default_tablespace,username from dba_users;
-- 查询指定用户默认表空间
select default_tablespace,username from dba_users where username='&u1' or username='&u2';
-- 查询每个分配和使用
define ts_name=&1
select t.tablespace_name name,d.allocated,u.used,f.free,t.status,d.cnt,contents,t.extent_management extman,
t.segment_space_management segman from dba_tablespaces t,
(select sum(bytes) allocated,count(file_id) cnt from dba_data_files
where tablespace_name='&&ts_name') d,
(select sum(bytes) free from dba_free_space
where tablespace_name='&&ts_name') f,
(select sum(bytes) used from dba_segments
where tablespace_name='&&ts_name') u
where t.tablespace_name='&&ts_name';

-- 创建表空间
create tablespace tp1 datafile 'tp1.dbf' size 1M;
select t.name tname,d.name dname,d.bytes from v$tablespace t join v$datafile d using(ts#) where t.name like 'TP1';
desc v$tablespace;
desc v$datafile;
create smallfile tablespace tp2
datafile 'tp2.dbf'
size 10M autoextend on next 1M maxsize 20M
extent management local autoallocate
segment space management auto;
select t.name tname,d.name dname,d.bytes from v$tablespace t join v$datafile d using(ts#) where t.name like 'TP2';

-- 重命名
alter tablespace tp2 rename to syl_tp;

-- 设置读写状态
alter tablespace tp1 read only;
alter tablespace tp1 read write;

-- 设置脱机，联机
alter tablespace tp1 offline normal;
alter tablespace tp1 online;

-- 显示表空间和数据文件中的可用空间百分比
SET PAGESIZE 100 LINES 132 ECHO OFF VERIFY OFF FEEDB OFF SPACE 1 TRIMSP ON
COMPUTE SUM OF a_byt t_byt f_byt ON REPORT
BREAK ON REPORT ON tablespace_name ON pf
COL tablespace_name FOR A17   TRU HEAD 'Tablespace|Name'
COL file_name       FOR A40   TRU HEAD 'Filename'
COL a_byt           FOR 9,990.999 HEAD 'Allocated|GB'
COL t_byt           FOR 9,990.999 HEAD 'Current|Used GB'
COL f_byt           FOR 9,990.999 HEAD 'Current|Free GB'
COL pct_free        FOR 990.0     HEAD 'File %|Free'
COL pf              FOR 990.0     HEAD 'Tbsp %|Free'
COL seq NOPRINT
DEFINE b_div=1073741824
--
SELECT 1 seq, b.tablespace_name, nvl(x.fs,0)/y.ap*100 pf, b.file_name file_name,
  b.bytes/&&b_div a_byt, NVL((b.bytes-SUM(f.bytes))/&&b_div,b.bytes/&&b_div) t_byt,
  NVL(SUM(f.bytes)/&&b_div,0) f_byt, NVL(SUM(f.bytes)/b.bytes*100,0) pct_free
FROM dba_free_space f, dba_data_files b
 ,(SELECT y.tablespace_name, SUM(y.bytes) fs
   FROM dba_free_space y GROUP BY y.tablespace_name) x
 ,(SELECT x.tablespace_name, SUM(x.bytes) ap
   FROM dba_data_files x GROUP BY x.tablespace_name) y
WHERE f.file_id(+) = b.file_id
AND   x.tablespace_name(+) = y.tablespace_name
and   y.tablespace_name =  b.tablespace_name
AND   f.tablespace_name(+) = b.tablespace_name
GROUP BY b.tablespace_name, nvl(x.fs,0)/y.ap*100, b.file_name, b.bytes
UNION
SELECT 2 seq, tablespace_name,
  j.bf/k.bb*100 pf, b.name file_name, b.bytes/&&b_div a_byt,
  a.bytes_used/&&b_div t_byt, a.bytes_free/&&b_div f_byt,
  a.bytes_free/b.bytes*100 pct_free
FROM v$temp_space_header a, v$tempfile b
  ,(SELECT SUM(bytes_free) bf FROM v$temp_space_header) j
  ,(SELECT SUM(bytes) bb FROM v$tempfile) k
WHERE a.file_id = b.file#
ORDER BY 1,2,4,3;

-- 调整表空间大小
alter database datafile 'tp1.dbf' resize 2m;
alter tablespace tp1 add datafile 'tp1_02.dbf' size 1m;

-- 删除表空间
alter tablespace tp1 offline;
drop tablespace tp1 including contents and datafiles;
drop tablespace syl_tp including contents cascade constraints;
select tablespace_name from dba_data_files;

-- 创建临时表空间
create temporary tablespace tmp_sp1 tempfile 'tmp_sp1.dbf' size 10M;
select tablespace_name from dba_temp_files;

-- 设置默认临时表空间
alter database default temporary tablespace tmp_sp1;
select * from database_properties where property_name='DEFAULT_TEMP_TABLESPACE';
alter database default temporary tablespace TEMP;

-- 创建临时表空间组
alter tablespace tmp_sp1 tablespace group tmpgroups;
select * from dba_tablespace_groups;
create temporary tablespace tmp_sp2 tempfile 'tmp_sp2.dbf' size 3M tablespace group tmpgroup2;

-- 删除临时表空间
drop tablespace tmp_sp2 including contents and datafiles;

create tablespace mvdata datafile 'mvdata.dbf' size 5m;
alter tablespace mvdata add datafile 'mvdata2.dbf' size 5m;
select t.name tname,d.name dname,d.bytes from v$tablespace t join v$datafile d using(ts#) where t.name='MVDATA';
alter database move datafile 'mvdata.dbf' to 'syl_mvdata.dbf';
select name from v$datafile;
alter tablespace mvdata drop datafile 'mvdata2.dbf';
drop tablespace mvdata including contents and datafiles;

-- 创建表
CREATE TABLE student(
  id		NUMBER,
  name		VARCHAR2(20),
  age		number(3),
  birthday	DATE	DEFAULT SYSDATE,
  note		CLOB
);
select * from tab where tname='STUDENT';
desc student;
INSERT INTO student(id,name,age,birthday,note) VALUES (1,'syl',19,TO_DATE('1999-01-01','yyyy-mm-dd'),'note test');
INSERT INTO student(id,name,age,birthday,note) VALUES (2,'lou',21,TO_DATE('1997-01-01','yyyy-mm-dd'),'note test');
select * from user_tables;

create table syl_stu as select * from student where name='syl';
select * from syl_stu;

-- 重命名表
RENAME student TO stu;
select * from tab where tname='STU';

select * from stu;

-- 修改表结构
-- 增加列
desc stu;
alter table stu add(address varchar2(50) default 'none');
select * from stu;
alter table stu add(email varchar2(50));
-- 修改列
alter table stu modify (name varchar2(30));
alter table stu modify (email default 'no email');
INSERT INTO stu(id,name,age,birthday,note) VALUES (3,'plus',19,TO_DATE('1999-01-01','yyyy-mm-dd'),'note test');
-- 重命名
alter table stu rename column address to saddress;
-- 删除
alter table stu drop (saddress);
--alter table stu drop column saddress;
alter table stu set unused (email);
alter table stu drop unused columns;

-- 复制表结构
create table stu_cp as select * from stu where 1=2;
desc stu_cp;
select * from stu_cp;

-- 删除表数据
commit;
delete from stu;
rollback;
truncate table stu;
rollback;
select * from stu;

-- 删除表
select * from tab where tabtype='TABLE';
drop table syl_stu;

-- 闪回flashback
show recyclebin;
select * from user_recyclebin;
CREATE TABLE syltp1_stu(
  id		NUMBER,
  name		VARCHAR2(20),
  age		number(3),
  birthday	DATE	DEFAULT SYSDATE,
  note		CLOB
)tablespace syltp1;
select * from tab where tname='SYLTP1_STU';

-- 约束
-- 非空
create table tech(id number,name varchar2(20) not null);
select * from tab where tname='&1';
desc tech;
insert into tech(id,name) values (1,'syl1');
insert into tech(id) values (2);
-- 唯一
alter table tech add(email varchar2(30) unique);
insert into tech(id,name,email) values (2,'syl2','syl2@qq.com');
insert into tech(id,name,email) values (3,'syl3','syl2@qq.com');
select * from tech;
/* col owner for a10;
col constraint_name for a20;
col table_name for a15;
*/
select owner,constraint_name,table_name from user_constraints where table_name='TECH';
select owner,constraint_name,table_name from user_constraints where constraint_name='SYS_C007385';
desc user_constraints;
select owner,constraint_name,table_name,column_name from user_cons_columns where constraint_name='SYS_C007385';
alter table tech add(cid varchar2(30),constraint uk_email unique(cid));
insert into tech(id,name,email,cid) values (3,'syl3','syl3@qq.com',1);
insert into tech(id,name,email,cid) values (4,'syl4','syl4@qq.com',1);
-- 主键
alter table tech add constraints pk_id primary key(id);
-- 检查
alter table tech add (sex varchar2(10),constraints chk_sex check(sex='man' or sex='female'));
-- 外键
-- 类别表
create table syl_category(
  cid number(5) primary key,
  name varchar2(30)
);
-- 课程表
create table syl_course(
  id number(10) primary key,
  name varchar2(30),
  cid number(5),
  constraint fk_cate foreign key(cid) references syl_category(cid) on delete cascade
);
insert into syl_category(cid,name) values (1,'cate1');
insert into syl_course(id,name,cid) values (1,'course1',1);
insert into syl_course(id,name,cid) values (2,'course1',2);
-- 删除约束
alter table tech drop constraint chk_sex;

-- SQL
-- 示例表
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
select * from student;
select * from course;
select * from sc;

-- 查询
select * from student where s_age between 20 and 50;
SELECT s_id,s_age,s_id+s_age,s_id-s_age,s_id*s_age,s_id/s_age FROM student;
SELECT * FROM student WHERE s_name LIKE '%2';
SELECT max(s_age),min(s_age) FROM student;
SELECT avg(grade),sum(grade) FROM sc WHERE s_id='1001';
SELECT grade FROM sc;
SELECT DISTINCT grade FROM sc;
SELECT count(s_id) FROM sc WHERE s_id=1001;
select concat(concat(s_name,'''s sex is '),s_sex) "sex" from student where s_id=1001;
-- 分组排序
SELECT s_id,count(*) FROM sc GROUP BY s_id;
SELECT s_id,sum(grade) FROM sc GROUP BY s_id;
SELECT s_id,grade, sum(grade) FROM sc GROUP BY s_id,grade;
-- having
SELECT s_id, sum(grade) FROM sc GROUP BY s_id HAVING sum(grade)>100;
-- order
SELECT s_id,sum(grade) AS sum_grade FROM sc GROUP BY s_id HAVING sum(grade)>100 ORDER BY sum(grade) DESC;
-- limit
SELECT * FROM student;
SELECT * FROM student where rownum<3;
-- 子查询
SELECT s_id,s_age FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=1);
SELECT  * FROM student WHERE s_id IN (SELECT s_id FROM sc WHERE c_id=(SELECT c_id FROM course WHERE c_time=(SELECT max(c_time) FROM course)));

-- 表的连接
select * from student,sc;
select * from student cross join sc;
select count(*) from student,sc;
select count(*) from student;
select count(*) from course;
select count(*) from sc;

select * from student,sc where student.s_id=sc.s_id;

--设置格式---
col s_name for a20;
col c_name for a15;
set linesize 500;
set pagesize 30;
-----------
SELECT sc.s_id,sc.c_id,s_name,c_name,grade,s_age,s_sex,c_time FROM student,course,sc WHERE student.s_id=sc.s_id AND course.c_id=sc.c_id;
SELECT sc.s_id, sc.c_id, s_name, c_name, grade FROM student, course, sc WHERE student.s_id=sc.s_id AND course.c_id=sc.c_id;

SELECT sc.s_id, sc.c_id, s.s_name, sc.grade FROM sc INNER JOIN student s ON s.s_id=sc.s_id;
SELECT s_id, sc.c_id, s.s_name, sc.grade FROM sc INNER JOIN student s using(s_id);
SELECT student.s_id,s_name,c_id,grade FROM student LEFT JOIN sc ON student.s_id=sc.s_id;
SELECT student.s_id,s_name,c_id,grade FROM student RIGHT JOIN sc ON student.s_id=sc.s_id;
SELECT student.s_id,s_name,c_id,grade FROM student FULL JOIN sc ON student.s_id=sc.s_id;
SELECT * FROM course NATURAL JOIN sc;
select * from course inner join sc on course.c_id=sc.c_id;

-- 视图
select * from user_views;
CREATE VIEW all_info AS SELECT sc.s_id,sc.c_id,s_name,c_name,grade,s_age,s_sex,c_time FROM student,course,sc WHERE student.s_id=sc.s_id AND course.c_id=sc.c_id;
select view_name from user_views;
select * from all_info;
desc SYS.USER_CONSTRAINTS;
select * from all_info where grade>80;
drop view all_info;

-- PL/SQL
BEGIN
  NULL;
END;
/

SET SERVEROUTPUT ON;
BEGIN
  DBMS_OUTPUT.put_line('Hello World');
END;
/

DECLARE
  v_name varchar2(20); --定义变量
BEGIN
  v_name := 'syl';  --为变量赋值
  DBMS_OUTPUT.put_line('my name is : ' || v_name);
END;
/

DECLARE
  v_sid NUMBER;            --接收学生编号
  v_sname VARCHAR2(20);    --接收学生姓名
BEGIN
  v_sid := &studentid;     --键盘输入数据
  SELECT s_name INTO v_sname FROM student WHERE s_id=v_sid; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
END;
/

DECLARE
  v_a NUMBER :=1;
  v_b NUMBER; 
BEGIN
  v_B := 2;
  DBMS_OUTPUT.put_line(v_A+v_B);
END;
/

DECLARE
  v_sid NUMBER NOT NULL := 1;
BEGIN
  NULL;
END;
/

DECLARE
  v_num CONSTANT NUMBER := 1;
  v_bool CONSTANT BOOLEAN := FALSE;
BEGIN
  NULL;
END;
/

DECLARE
  v_sid student.s_id%TYPE;            --接收学生编号
  v_sname student.s_name%TYPE;    --接收学生姓名
BEGIN
  v_sid := &studentid;     --键盘输入数据
  SELECT s_name INTO v_sname FROM student WHERE s_id=v_sid; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
END;
/

select * from student;
DECLARE
  v_row student%ROWTYPE;
BEGIN
  SELECT * INTO v_row FROM student WHERE s_id=1001;
  DBMS_OUTPUT.put_line('1001 student is : ' || v_row.s_name || v_row.s_sex || v_row.s_age);
END;
/

DECLARE
  v_sname student.s_name%TYPE;
BEGIN
  SELECT s_name INTO v_sname FROM student WHERE s_age BETWEEN 20 AND 50;
  DBMS_OUTPUT.put_line(v_sname);
END;
/

DECLARE
  v_a NUMBER :=1;
  v_b NUMBER :=2;
  v_c NUMBER;
  v_d VARCHAR2(20);
BEGIN
  IF v_a<v_b THEN
    DBMS_OUTPUT.put_line(v_a || ' < ' || v_b);
  END IF;
  IF v_c IS NULL THEN
    DBMS_OUTPUT.put_line('v_c is null');
  END IF;
  IF v_b BETWEEN 1 AND 3 THEN
    DBMS_OUTPUT.put_line('v_b is between 1 and 3');
  END IF;
  IF v_b IN(1,2,3) THEN
    DBMS_OUTPUT.put_line('v_b is : ' || v_b);
  END IF;
  IF v_d LIKE 'shi%' THEN
    DBMS_OUTPUT.put_line(v_d);
  END IF;
END;
/

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

DECLARE
  p1 PLS_INTEGER := 2147483647;
  p2 PLS_INTEGER := 1;
  n NUMBER;
BEGIN
  n := p1 + p2;
END;
/

DECLARE
  p1 BINARY_INTEGER := 2147483647;
  p2 BINARY_INTEGER := 1;
  n NUMBER;
BEGIN
  n := p1 + p2;
END;
/

DECLARE
  v_float BINARY_FLOAT := 6666.66F;
  v_double BINARY_DOUBLE :=6666.66F;
BEGIN
  DBMS_OUTPUT.put_line(v_float);
  DBMS_OUTPUT.put_line(v_double);
END;
/

BEGIN
  DBMS_OUTPUT.put_line('BINARY_FLOAT_MIN_NORMAL = ' || BINARY_FLOAT_MIN_NORMAL);
  DBMS_OUTPUT.put_line('BINARY_FLOAT_MAX_NORMAL = ' || BINARY_FLOAT_MAX_NORMAL);
END;
/

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

DECLARE
  v_char NCHAR(5);
  v_varchar2 NVARCHAR2(5);
BEGIN
  v_char := '实验楼';
  v_varchar2 := '实验楼';
  DBMS_OUTPUT.put_line(v_char || ' length: ' || LENGTH(v_char));
  DBMS_OUTPUT.put_line(v_varchar2 || ' length: ' || LENGTH(v_varchar2));
END;
/

DECLARE
  v_long LONG;
  v_longraw LONG RAW;
BEGIN
  v_long := 'SYL';
  v_longraw := UTL_RAW.cast_to_raw('SYL');
  DBMS_OUTPUT.put_line(v_long || ' length: ' || LENGTH(v_long));
  DBMS_OUTPUT.put_line(v_longraw || ' length: ' || LENGTH(v_longraw));
  DBMS_OUTPUT.put_line(UTL_RAW.cast_to_varchar2(v_longraw) || ' length: ' || LENGTH(v_longraw));
END;
/

DECLARE
  v_rowid ROWID;
  v_urowid UROWID;
BEGIN
  SELECT ROWID INTO v_rowid FROM student WHERE s_id=1001;
  SELECT ROWID INTO v_urowid FROM student WHERE s_id=1001;
  DBMS_OUTPUT.put_line('v_rowid = '||v_rowid || '  v_urowid = '||v_urowid);
END;
/

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

DECLARE
  v_d DATE := SYSDATE;
BEGIN
  DBMS_OUTPUT.put_line(TO_CHAR(v_d));
END;
/
SHOW PARAMETER NLS_DATE_LANGUAGE;
SHOW PARAMETER NLS_DATE_FORMAT;
select * from nls_session_parameters;

ALTER SESSION SET NLS_DATE_LANGUAGE='AMERICAN';
ALTER SESSION SET NLS_DATE_LANGUAGE='SIMPLIFIED CHINESE';
SELECT SYSDATE FROM DUAL;
ALTER SESSION SET NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss';
SELECT SYSDATE FROM DUAL;

DECLARE
  v_timezone TIMESTAMP WITH TIME ZONE := SYSTIMESTAMP;
  v_localtime TIMESTAMP WITH LOCAL TIME ZONE := SYSTIMESTAMP;
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_timezone);
  DBMS_OUTPUT.PUT_LINE(v_localtime);
END;
/

DECLARE
  v_interval INTERVAL YEAR(3) TO MONTH := INTERVAL '5-1' YEAR TO MONTH;
  v_interval2 INTERVAL DAY(3) TO SECOND := INTERVAL '5 11:11:11.1111' DAY TO SECOND;
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_interval);
  DBMS_OUTPUT.PUT_LINE(v_interval+SYSDATE);
  DBMS_OUTPUT.PUT_LINE(v_interval2);
  DBMS_OUTPUT.PUT_LINE(v_interval2+SYSDATE);
END;
/

DECLARE
  SUBTYPE name_subtype IS VARCHAR2(20) NOT NULL;
  v_name name_subtype := 'syl';
BEGIN
  DBMS_OUTPUT.PUT_LINE(v_name);
END;
/

select * from student;
select * from sc;
select * from student s join sc using(s_id);
select s_name from student s join sc using(s_id) group by s_name;
select * from student s join sc using(s_id) where s_sex='man';
select count(*) from sc where grade > 70;

select s_id,avg(grade) from student s join sc using(s_id) group by s_id having s_id=1003;

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
 
select * from student; 
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

declare
  v_i number := 1;
begin
  loop
    dbms_output.put_line(v_i);
    exit when v_i>=3;
    v_i := v_i+1;
  end loop;
end;
/

declare
  v_i number := 1;
begin
  while(v_i <= 3) loop
    dbms_output.put_line(v_i);
    v_i := v_i+1;
  end loop;
end;
/

declare
  v_i number :=1;
begin
  for v_i in 1 .. 3 loop
    dbms_output.put_line(v_i);
  end loop;
end;
/

declare
  v_i number :=1;
begin
  for v_i in reverse 1 .. 3 loop
    dbms_output.put_line(v_i);
  end loop;
end;
/

DECLARE
  v_i NUMBER :=1;
BEGIN
  FOR v_i IN 1 .. 5 LOOP
    IF v_i = 3 THEN
      --EXIT;
      --CONTINUE;
      GOTO flag;
    END IF;
    dbms_output.put_line(v_i);
  END LOOP;
  <<flag>>
  dbms_output.put_line('goto');
END;
/

DECLARE
  v_a VARCHAR2(20) := 'this is global';
BEGIN
  DECLARE
    v_a VARCHAR2(20) := 'this is inner';
  BEGIN
    DBMS_OUTPUT.put_line(v_a);
  END;
  DBMS_OUTPUT.put_line(v_a);
END;
/
    
DECLARE
  p1 PLS_INTEGER := 2147483647;
  p2 PLS_INTEGER := 1;
  n NUMBER;
BEGIN
  n := p1 + p2;
EXCEPTION
  WHEN 
END;
/

DECLARE
  v_a NUMBER := 1;
  v_b NUMBER := 0;
BEGIN
  v_a := v_a/v_b;
EXCEPTION
  WHEN ZERO_DIVIDE THEN
    DBMS_OUTPUT.put_line('zero divide');
    DBMS_OUTPUT.put_line(SQLCODE);
    DBMS_OUTPUT.put_line(SQLERRM);
END;
/

select * from all_plsql_object_settings;
select distinct plsql_warnings from all_plsql_object_settings;  
  
DECLARE
  v_sid NUMBER;            --接收学生编号
  v_sname VARCHAR2(20);    --接收学生姓名
BEGIN
  v_sid := &studentid;     --键盘输入数据
  SELECT s_name INTO v_sname FROM student WHERE s_id=v_sid; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
EXCEPTION
  WHEN no_data_found THEN
    DBMS_OUTPUT.put_line('not found the student');
END;
/

select * from student;
DECLARE
  v_sname VARCHAR2(20);    --接收学生姓名
BEGIN
  SELECT s_name INTO v_sname FROM student WHERE s_age>10; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
EXCEPTION
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.put_line('too many rows');
END;
/

DECLARE
  v_sname VARCHAR2(20);    --接收学生姓名
BEGIN
  SELECT s_name INTO v_sname FROM student WHERE s_age>10; --把查询出来的值赋给变量 v_sname
  DBMS_OUTPUT.put_line('student''s name is : ' || v_sname);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line(SQLCODE || ':' || SQLERRM);
END;
/

DECLARE
  v_a NUMBER := 1;
  v_exception EXCEPTION;
BEGIN
  IF v_a = 1 THEN
    RAISE v_exception;  --抛出异常
  END IF;
EXCEPTION
  WHEN v_exception THEN
    DBMS_OUTPUT.put_line('exception:is 1');
    DBMS_OUTPUT.put_line(SQLCODE);
    DBMS_OUTPUT.put_line(SQLERRM);
END;
/

DECLARE
  v_a NUMBER := 1;
  v_exception EXCEPTION;  --声明异常
  PRAGMA EXCEPTION_INIT(v_exception,-20666);
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


DECLARE
  v_a NUMBER := 1;
  v_exception EXCEPTION;  --声明异常
  PRAGMA EXCEPTION_INIT(v_exception,-20666);
BEGIN
  IF v_a = 1 THEN
    RAISE_APPLICATION_ERROR(-20666,'raise application error');  --抛出异常
  END IF;
EXCEPTION 
  WHEN v_exception THEN   --捕获异常
    DBMS_OUTPUT.put_line(SQLCODE);
    DBMS_OUTPUT.put_line(SQLERRM);
END;
/


DECLARE
  v_a NUMBER := 2;
  --v_exception EXCEPTION;  --声明异常
  --PRAGMA EXCEPTION_INIT(v_exception,-20666);
BEGIN
  IF v_a = 1 THEN
    RAISE_APPLICATION_ERROR(-20666,'raise application error');  --抛出异常
  ELSE
    RAISE_APPLICATION_ERROR(-20667,'raise application error 2'); 
  END IF;
EXCEPTION 
  WHEN OTHERS THEN   --捕获异常
    DBMS_OUTPUT.put_line(SQLCODE);
    DBMS_OUTPUT.put_line(SQLERRM);
END;
/

-- 实例管理
select name,value from v$parameter order by name;  --查看参数及其当前值(当前运行实例中生效的参数值）
select name,value from v$spparameter order by name; --磁盘上 spfile 中存储的值
--原因：有些参数可以在实例运行时更改。第二句结果如果全是null的原因：因为从pfile启动（客户端）而不是从spfile启动（服务端）。
--alter system set dbfips_140=false scope=spfile;
--基本实例参数，每个数据库使用的参数
select name,value from v$parameter where isbasic='TRUE' order by name; 
select s.name,s.value from v$spparameter s join v$parameter p on s.name=p.name where isbasic='TRUE' order by name; 
--两个命令差异的原因：某些参数已应用实例，但尚未应用于 spfile
-- v$parameter --> https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/V-PARAMETER.html#GUID-C86F3AB0-1191-447F-8EDF-4727D8693754
-- 基本初始化参数 --> https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/basic-initialization-parameters.html#GUID-D75F1A77-47E2-4F35-B145-44B3A10ED85C
-- parameter by functional category --> https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/changing-parameter-values-in-a-parameter-file.html#GUID-4C578B21-DE2B-4210-8EB7-EF28D36CC1CB
show parameter cluster_database;
-- alter sesison,alter system --> https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/changing-parameter-values-in-a-parameter-file.html#GUID-43A4AD97-2009-4275-8802-DA6299DFDCAD

--更改参数
select p.value in_effect,s.value in_file from v$parameter p join v$spparameter s on p.name=s.name where p.name='db_file_multiblock_read_count';
alter system set db_file_multiblock_read_count=16 scope=memory;
alter system set db_file_multiblock_read_count=64 scope=spfile;
select p.value in_effect,s.value in_file from v$parameter p join v$spparameter s on p.name=s.name where p.name='db_file_multiblock_read_count';
alter system reset db_file_multiblock_read_count;  --重置spfile的值

alter system set log_buffer=10m;   --报错，静态参数，必须使用 scope=spfile 进行更改。重启实例后生效。

alter session set optimizer_mode=first_rows;
show parameter optimizer_mode;

--练习13-2 
select name,value,isdefault from v$parameter where isbasic='TRUE' and name='processes' or name='sessions' order by name;
--processes:限制允许连接到实例的操作系统进程数量。sessions限制会话数量。
alter system set processes=200 scope=spfile; --静态参数
startup force --重启数据库
--设置语言NLS_LANGUAGE
alter session set nls_language='SIMPLIFIED CHINESE';
--查询系统日期
select to_char(sysdate,'day') from dual;

select name,value from v$spparameter where name='nls_language';
select * from v$nls_parameters;
select userenv('language') from dual;

desc v$parameter;
select * from v$parameter;
select name,value from v$parameter;
select name,value from v$spparameter;
show parameters;
select p.value in_effect,s.value in_file from v$parameter p join v$spparameter s on p.name=s.name where p.name='allow_global_dblinks';
alter system set allow_global_dblinks=TRUE scope=memory;
select p.value in_effect,s.value in_file from v$parameter p join v$spparameter s on p.name=s.name where p.name='processes';
alter system set processes=400;
alter system set processes=400 scope=spfile;
alter system reset processes;
alter system set processes=300 scope=spfile;
select * from v$parameter where name='approx_for_aggregation';

select name,value,isses_modifiable from v$parameter where isses_modifiable='TRUE';
show parameter approx_for_aggregation;
alter session set approx_for_aggregation=TRUE;
alter session set approx_for_aggregation=FALSE;

--启动，关闭实例
startup;
select * from v$spparameter where name='control_files';

--警报日志
select name,value from v$spparameter where name='diagnostic_dest';
--ddl log
select name,value from v$parameter where name='enable_ddl_logging';
alter system set enable_ddl_logging=TRUE;

--动态性能视图
select t.name,d.name,d.bytes from v$tablespace t join v$datafile d on t.ts#=d.ts# order by t.name;
select t.tablespace_name,d.file_name,d.bytes from dba_tablespaces t join dba_data_files d on t.tablespace_name=d.tablespace_name order by tablespace_name;
select m.group#,m.member,g.bytes from v$log g join v$logfile m on m.group#=g.group# order by m.group#,m.member;
select owner,object_name,object_type from dba_objects where object_name like 'V%PARAMETER';

select tablespace_name from dba_tablespaces;
select name from v$tablespace;
select * from v$controlfile;
select value from v$parameter where name ='control_files';
--查看动态性能视图有哪些
select * from v$fixed_table where name like 'V$%';
select * from v$fixed_table order by name;

--用户管理
-创建用户
create user syl identified by shiyanlou;
select username,created from dba_users where lower(username)='syl';
select default_tablespace,temporary_tablespace from dba_users where username='SYL';
select property_name,property_value from database_properties where property_name like '%TABLESPACE%';
select tablespace_name,bytes,max_bytes from dba_ts_quotas;
select * from dba_users where username='SYL';
select * from dba_tablespaces;
select t.name,d.name,d.bytes/1024/1024 "BYTES(M)" from v$tablespace t join v$datafile d on t.ts#=d.ts# order by t.name;

create user syl2 identified externally
default tablespace SYLTP1
quota 1m on SYLTP1
TEMPORARY TABLESPACE TMP_SP1
PROFILE default;
select * from dba_users where username='SYL2';
select * from dba_profiles order by profile;
CREATE PROFILE new_profile
  LIMIT PASSWORD_REUSE_MAX 10
        PASSWORD_REUSE_TIME 30;
drop profile new_profile cascade;

--修改
alter user syl identified by newsyl;
alter user syl default tablespace SYLTP1;
--删除
drop user syl2 cascade;


--权限管理
grant create session to syl;
select * from dba_sys_privs where grantee='SYL';
/*grant create session,alter session,create table,create view,create synonym,
create cluster,create database link,create sequence,create trigger,create type,create procedure,create operator to syl;
*/
--系统权限
grant all privileges to syl;
grant create session to syl with admin option;
--对象权限
select * from tab;
grant select on system.student to syl;
select * from dba_tab_privs where grantee='SYL';

--撤销权限
revoke all privileges from syl;
revoke select on system.student from syl;

select * from v$pwfile_users;

--角色管理
select * from student;
select * from sc;
select * from course;

create role user_sc;
grant create session to user_sc;
grant select on system.student to user_sc;
grant select on system.sc to user_sc;
grant select on system.course to user_sc;

create role admin_sc;
grant user_sc to admin_sc;
grant select on system.student to admin_sc;
grant delete on system.student to admin_sc;
grant insert on system.student to admin_sc;
grant update on system.student to admin_sc;
grant select on system.sc to admin_sc;
grant delete on system.sc to admin_sc;
grant insert on system.sc to admin_sc;
grant update on system.sc to admin_sc;
grant select on system.course to admin_sc;
grant delete on system.course to admin_sc;
grant insert on system.course to admin_sc;
grant update on system.course to admin_sc;

/*create role user_sc;
grant select on system.student to admin_sc;
grant select on system.sc to admin_sc;
grant select on system.course to admin_sc;
*/

create role super_sc;
grant admin_sc to super_sc;
grant create any table,drop any table to super_sc;
grant all on system.student to super_sc;
grant all on system.sc to super_sc;
grant all on system.course to super_sc;

select granted_role,default_role from dba_role_privs where grantee='SYSTEM';

select * from dba_users;
select * from dba_roles;
--设置角色
/*drop user syl_stu1 cascade;
drop user syl_stu2 cascade;
drop user syl_admin cascade;
drop user syl_super cascade;
*/

create user syl_stu1 identified by sylstu1;
create user syl_stu2 identified by sylstu2;
create user syl_admin identified by syladmin;
create user syl_super identified by sylsuper;
select * from dba_users order by created desc;

grant user_sc to syl_stu1;
grant user_sc,admin_sc to syl_stu2;
grant admin_sc to syl_admin;
grant super_sc to syl_super;
--select * from dba_sys_privs;
select * from dba_role_privs;

conn syl_stu2/sylstu2;
set role user_sc;

conn system/Syl12345
alter role user_sc identified by usersc;
alter role super_sc identified by supersc;
alter role super_sc not identified;

grant insert on system.student to user_sc;
--select * from dba_role_privs where granted_role='USER_SC';
select * from dba_sys_privs where grantee='USER_SC';
select * from dba_tab_privs where grantee='USER_SC';

revoke insert on system.student from user_sc;
drop role super_sc;
select * from dba_roles where role='SUPER_SC';

--概要文件
create profile pwd_time 
	limit failed_login_attempts 3   --限制连续错误次数
		password_lock_time 1;       --限制锁定账户天数
select distinct profile from dba_profiles;

alter profile pwd_time limit sessions_per_user 100;
select * from dba_profiles where profile='PWD_TIME' and resource_name='SESSIONS_PER_USER';
drop profile pwd_time cascade;

