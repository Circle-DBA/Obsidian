

## 1. 实例里有哪些库

```
select schema_name,
       default_character_set_name as charset,
       default_collation_name     as collation
  from information_schema.schemata
 where schema_name not in ('information_schema','mysql','performance_schema','sys')
 order by schema_name;
```

## 2. 每个库多大（数据 + 索引）

```
select table_schema as db,
       count(*) as tables,
       round(sum(data_length)/1024/1024, 2)                    as data_mb,
       round(sum(index_length)/1024/1024, 2)                   as idx_mb,
       round(sum(data_length + index_length)/1024/1024, 2)     as total_mb
  from information_schema.tables
 where table_schema not in ('information_schema','mysql','performance_schema','sys')
 group by table_schema
 order by total_mb desc;
```

## 3. 某个库的表清单（行数估算 + 大小 + 引擎）

```
select table_name,
       engine,
       table_rows,
       round((data_length + index_length)/1024/1024, 2) as mb,
       table_comment
  from information_schema.tables
 where table_schema = 'dbname'
   and table_type   = 'BASE TABLE'
 order by (data_length + index_length) desc;
```

`table_rows` 是 InnoDB 的**采样估算值**，小表经常差得离谱，甚至显示 0；要精确值，只能执行 `select count(*) from db.tbl`（全表扫描，大表很慢），或者先执行 `analyze table db.tbl`，让统计值刷新一次。

## 4. 查表结构（列定义）

```
select ordinal_position, column_name, column_type,
       is_nullable, column_default, column_key, extra, column_comment
  from information_schema.columns
 where table_schema = 'dbname' and table_name = 'tbl'
 order by ordinal_position;
```

看建表语句原文更省事：`show create table dbname.tbl\G`

## 5. 查索引

```
select index_name, seq_in_index, column_name,
       non_unique, index_type, cardinality
  from information_schema.statistics
 where table_schema = 'dbname' and table_name = 'tbl'
 order by index_name, seq_in_index;
```

`cardinality` 偏低通常意味着索引选择性差，或者统计过期（可以先 `analyze table` 后再看）。

## 6. 反查字段出现在哪些表（改字段前必做）

```
select table_schema, table_name, column_name, column_type
  from information_schema.columns
 where column_name like '%user_id%'
   and table_schema not in ('information_schema','mysql','performance_schema','sys');
```

## 7. 表碎片 / 可回收空间

```
select table_name,
       round(data_free/1024/1024, 2) as free_mb,
       round((data_length + index_length)/1024/1024, 2) as total_mb
  from information_schema.tables
 where table_schema = 'dbname'
   and data_free > 0
 order by data_free desc;
```

`free_mb` 大说明做过大量删除，可以考虑 `optimize table`（会锁表 / 重建，别在业务高峰做）。

## 8. 当前在跑什么、谁在等锁

```
-- 当前连接与正在执行的语句
show full processlist;

-- 8.0：锁等待关系
select * from performance_schema.data_lock_waits;

-- 5.7：锁等待关系
select * from information_schema.innodb_lock_waits;
```