
这段存储过程的**主干逻辑（fetch → 判空 → 处理 → 再 fetch）是对的**，但有几处会让它静默出错，或者跑到一半直接中断。按严重程度排：

## 一、会出错 / 结果不正确

1. **`varchar(63)` 装不下标识符**。MySQL 的库名、表名上限是 **64** 字符，`scname/tbname` 用 63 会截断最后一个字符，拼出来的 SQL 指向不存在的表。应改 `varchar(64)`。
2. **`table_name` 列长度不够**。你插入的是 `schema.table`，最长 `64+1+64=129` 字符。如果目标表该列是 `varchar(63)`，严格模式下直接报 _Data too long_，非严格模式静默截断成两个同名的行。
3. **元数据里含引号会破坏拼接**。库表名允许含反引号（`` ` ``），而 `lower('...')` 里的值没做单引号转义，名字里带 `'` 就会把拼出来的 SQL 提前闭合。必须 `replace(x,'''','''''')` 处理字符串、`replace(x,'`','``')` 处理标识符。
4. **重复调用会重复插入**。过程里没有 `truncate`，第二次跑结果翻倍。而 `tmp_` 前缀但不是 `TEMPORARY` 表，多会话并发会互相污染。
5. **没有异常处理**。任何一张表 `execute` 失败（权限、表被并发 drop、锁等待超时），整个循环中断，`stmt1` 不 dealloc、游标不 close，后续调用在同一会话里可能撞上残留的 prepare 名。
6. **`left join information_schema.views` 是多余的**。`information_schema.tables` 里视图本来就有记录，直接 `where table_type='BASE TABLE'` 一步到位，还少扫一遍元数据。

## 二、性能（这是实践中最疼的）

`count(*)` 在 InnoDB 上是**全表扫描**，大库跑完可能要几十分钟，期间还会占 buffer pool、拉高 IO。如果只是要 "规模概览"，用 `TABLE_ROWS` 估算（秒级完成，代价是误差：小表误差大，大表可能偏 ±20~50%）。建议把两种模式都留着，按需选。

## 三、修正版（可直接整段执行）

```
create table if not exists tmp_get_actural_table_count (
  `table_name`   varchar(200) not null,
  `table_cnt`    bigint       not null,
  `collected_at` datetime     not null default current_timestamp,
  key `idx_tbl` (`table_name`)
) engine=innodb default charset=utf8mb4;

truncate table tmp_get_actural_table_count;
drop procedure if exists get_actural_table_count;

delimiter //
create procedure get_actural_table_count()
begin
  declare v_sql    longtext;
  declare v_scname varchar(64) default '';
  declare v_tbname varchar(64) default '';
  declare v_done   tinyint     default 0;
  declare v_errno  int         default 0;
  declare v_msg    text;

  declare c_tbl cursor for
    select table_schema, table_name
      from information_schema.tables
     where table_type = 'BASE TABLE'
       and table_schema not in ('information_schema','mysql','performance_schema','sys')
     order by table_schema, table_name;

  declare continue handler for not found set v_done = 1;

  declare exit handler for sqlexception
  begin
    get diagnostics condition 1 v_errno = mysql_errno(), v_msg = message_text();
    set @sql_1 = null;
    resignal;
  end;

  open c_tbl;

  read_loop: loop
    fetch c_tbl into v_scname, v_tbname;
    if v_done = 1 then
      leave read_loop;
    end if;

    set v_sql = concat(
      'insert into tmp_get_actural_table_count(`table_name`,`table_cnt`) ',
      'select lower(concat(''', replace(v_scname,'''',''''''), '.', replace(v_tbname,'''',''''''), ''')), ',
      'count(*) from `', replace(v_scname,'`','``'), '`.`', replace(v_tbname,'`','``'), '`'
    );

    set @sql_1 = v_sql;
    prepare stmt1 from @sql_1;
    execute stmt1;
    deallocate prepare stmt1;
  end loop;

  close c_tbl;
  set @sql_1 = null;
end //
delimiter ;

call get_actural_table_count();
```

改动点：`table_type` 直取、变量 64 宽、字符串 / 标识符双重转义、`read_loop + leave` 替掉 `while num<>1`（语义更明确，也不会被循环体内其他 `SELECT ... INTO` 的 NOT FOUND 误触发）、`exit handler` 保证失败时不留残渣。

## 四、估算版（秒级，替代方案）

```
truncate table tmp_get_actural_table_count;
insert into tmp_get_actural_table_count(`table_name`,`table_cnt`)
select lower(concat(table_schema,'.',table_name)), table_rows
  from information_schema.tables
 where table_type='BASE TABLE'
   and table_schema not in ('information_schema','mysql','performance_schema','sys');
```

## 五、想一条 SQL 干完所有表（无游标）

```
set session group_concat_max_len = 4294967295;
set @s = null;
select group_concat(concat(
  'select lower(''', replace(table_schema,'''',''''''), '.', replace(table_name,'''',''''''), ''') as t, count(*) as c from `',
  replace(table_schema,'`','``'), '`.`', replace(table_name,'`','``'), '`') separator ' union all ')
  into @s
 from information_schema.tables
where table_type='BASE TABLE'
  and table_schema not in ('information_schema','mysql','performance_schema','sys');
set @s = concat('insert into tmp_get_actural_table_count(`table_name`,`table_cnt`) ', @s);
prepare st from @s; execute st; deallocate prepare st;
```

这条路要先确认 `length(@s) < @@max_allowed_packet`（表特别多时 `group_concat` 会**静默截断**，只算到一半的表就悄悄停了，比报错更危险）。游标版反而更安全，只是慢一点。

一句话总结：游标骨架不用改，**重点修 63→64 的长度、`schema.table` 的列宽 200、引号转义、truncate 与失败清理**；剩下的要不要精确 `count(*)`，取决于你能接受多久的等待。