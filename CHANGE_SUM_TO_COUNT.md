# Background
When execute command to load primary key to buffer pool, what command should we do? <br/>
`select count(*) from table_name` <br/>
or `select count(*) from table_name where non_index_column = 0 or non_index_column = '0'`<br/>
or `select sum(primary_key) from table_name` ?

#### TL;DR
1. Table with only primary key:
    * `select count(*) from table_name where non_index_column = 0 or non_index_column = '0'` has the greatest pages loaded.
    * `select count(*) from table_name` and `select sum(primary_key) from table_name` has the same result, and the loaded pages is less than query has `where non_index_column = 0 or non_index_column = '0'` condition.

2. Table with primary and other index(es):
    * `select count(*) from table_name`: **primary_key** will be loaded.
    * `select sum(primary_key) from table_name`: **other_index** will be loaded.
    * `select count(*) from table_name where non_index_column = 0 or non_index_column = '0'`: **primary_key** will be loaded with the greatest.

# Testing
### Testing environment
* Mysql version `5.7.17`
* Buffer pool configuration:
    ```
    mysql> show variables like '%buffer_pool%';
    +-------------------------------------+----------------+
    | Variable_name                       | Value          |
    +-------------------------------------+----------------+
    | innodb_buffer_pool_chunk_size       | 134217728      |
    | innodb_buffer_pool_dump_at_shutdown | OFF            |
    | innodb_buffer_pool_dump_now         | OFF            |
    | innodb_buffer_pool_dump_pct         | 25             |
    | innodb_buffer_pool_filename         | ib_buffer_pool |
    | innodb_buffer_pool_instances        | 1              |
    | innodb_buffer_pool_load_abort       | OFF            |
    | innodb_buffer_pool_load_at_startup  | OFF            |
    | innodb_buffer_pool_load_now         | OFF            |
    | innodb_buffer_pool_size             | 134217728      |
    +-------------------------------------+----------------+
    10 rows in set (0.01 sec)
    ```

* Database `test_mysql_dump` has only table `test_data` with 10M rows, configurations as below:

    ```
    mysql> select table_name, engine from information_schema.tables where table_schema = 'test_mysql_warmup';
    +------------+--------+
    | table_name | engine |
    +------------+--------+
    | test_data  | InnoDB |
    +------------+--------+
    1 row in set (0.00 sec)
    ```

    and
    ```
    mysql> desc test_data;
    +-------------+--------------+------+-----+---------+-------+
    | Field       | Type         | Null | Key | Default | Extra |
    +-------------+--------------+------+-----+---------+-------+
    | id          | int(11)      | NO   | PRI | NULL    |       |
    | random_str  | varchar(255) | YES  |     | NULL    |       |
    | created_at  | varchar(255) | YES  |     | NULL    |       |
    | random_str1 | varchar(255) | YES  |     | NULL    |       |
    | random_str2 | varchar(255) | YES  |     | NULL    |       |
    | random_str3 | varchar(255) | YES  |     | NULL    |       |
    +-------------+--------------+------+-----+---------+-------+
    6 rows in set (0.00 sec)
    ```

### Test scenario (Restart mysql before each testing with each command)
1. **Compare above 3 command when table `test_data` has only primary key as index**:
    * Testing with command: `select sum(id) from test_data;`:

        ```
        mysql> select sum(id) from test_data;
        +----------------+
        | sum(id)        |
        +----------------+
        | 50000005000000 |
        +----------------+
        1 row in set (12.46 sec)
        ```
        **Buffer poll infos**
        ```
        mysql> select table_name as Table_Name, index_name as Index_Name, count(*) as Page_Count, sum(data_size)/1024/1024 as Size_in_MB from information_schema.innodb_buffer_page group by table_name, index_name order by Size_in_MB desc limit 5;
        +---------------------------------+------------+------------+--------------+
        | Table_Name                      | Index_Name | Page_Count | Size_in_MB   |
        +---------------------------------+------------+------------+--------------+
        | `test_mysql_warmup`.`test_data` | PRIMARY    |       7940 | 106.90351486 |
        | `SYS_TABLES`                    | CLUST_IND  |         86 |   1.20526028 |
        | `SYS_COLUMNS`                   | CLUST_IND  |          3 |   0.02067661 |
        | `mysql`.`innodb_index_stats`    | PRIMARY    |          2 |   0.01506424 |
        | `SYS_FIELDS`                    | CLUST_IND  |          1 |   0.00902271 |
        +---------------------------------+------------+------------+--------------+
        5 rows in set (0.07 sec)
        ```

        => **Primary key** is loaded with **7940 pages**

    * Testing with command: `select count(*) from test_data;`:

        ```
        mysql> select count(*) from test_data;
        | count(*) |
        +----------+
        | 10000000 |
        +----------+
        1 row in set (11.68 sec)
        ```

        **Buffer poll infos**
        ```
        mysql> select table_name as Table_Name, index_name as Index_Name, count(*) as Page_Count, sum(data_size)/1024/1024 as Size_in_MB from information_schema.innodb_buffer_page group by table_name, index_name order by Size_in_MB desc limit 5;
        +---------------------------------+------------+------------+--------------+
        | Table_Name                      | Index_Name | Page_Count | Size_in_MB   |
        +---------------------------------+------------+------------+--------------+
        | `test_mysql_warmup`.`test_data` | PRIMARY    |       7940 | 106.90351486 |
        | `SYS_TABLES`                    | CLUST_IND  |         86 |   1.20526028 |
        | `SYS_COLUMNS`                   | CLUST_IND  |          3 |   0.02067661 |
        | `mysql`.`innodb_index_stats`    | PRIMARY    |          2 |   0.01506424 |
        | `SYS_FIELDS`                    | CLUST_IND  |          1 |   0.00902271 |
        +---------------------------------+------------+------------+--------------+
        5 rows in set (0.08 sec)
        ```
        => **Primary key** is loaded with **7940 pages**

    * Testing with command: `select count(*) from test_data where random_str = 0 or random_str = '0';`:

        ```
        mysql> select count(*) from test_data where random_str = 0 or random_str = '0';
        +----------+
        | count(*) |
        +----------+
        | 10000000 |
        +----------+
        1 row in set, 65535 warnings (19.08 sec)
        ```

        **Buffer pool infos**
        ```
        mysql> select table_name as Table_Name, index_name as Index_Name, count(*) as Page_Count, sum(data_size)/1024/1024 as Size_in_MB from information_schema.innodb_buffer_page group by table_name, index_name order by Size_in_MB desc limit 5;
        +---------------------------------+------------+------------+--------------+
        | Table_Name                      | Index_Name | Page_Count | Size_in_MB   |
        +---------------------------------+------------+------------+--------------+
        | `test_mysql_warmup`.`test_data` | PRIMARY    |       8025 | 108.04996300 |
        | `SYS_COLUMNS`                   | CLUST_IND  |          3 |   0.02067661 |
        | `SYS_FIELDS`                    | CLUST_IND  |          1 |   0.00906658 |
        | `SYS_TABLES`                    | CLUST_IND  |          2 |   0.00766659 |
        | `SYS_INDEXES`                   | CLUST_IND  |          1 |   0.00720882 |
        +---------------------------------+------------+------------+--------------+
        ```
        => **Primary key** is loaded with **8025 pages**

2. **Compare above 3 command when table `test_data` has primary key `id` and field `random_str` as index**
    * First, add index to field `random_str`:

        ```
        mysql> create index test_data_random_str_index on test_data(random_str);
        Query OK, 0 rows affected (52.24 sec)
        Records: 0  Duplicates: 0  Warnings: 0

        mysql> desc test_data;
        +-------------+--------------+------+-----+---------+-------+
        | Field       | Type         | Null | Key | Default | Extra |
        +-------------+--------------+------+-----+---------+-------+
        | id          | int(11)      | NO   | PRI | NULL    |       |
        | random_str  | varchar(255) | YES  | MUL | NULL    |       |
        | created_at  | varchar(255) | YES  |     | NULL    |       |
        | random_str1 | varchar(255) | YES  |     | NULL    |       |
        | random_str2 | varchar(255) | YES  |     | NULL    |       |
        | random_str3 | varchar(255) | YES  |     | NULL    |       |
        +-------------+--------------+------+-----+---------+-------+
        6 rows in set (0.00 sec)

        mysql> show index from test_data;
        +-----------+------------+----------------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
        | Table     | Non_unique | Key_name                   | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
        +-----------+------------+----------------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
        | test_data |          0 | PRIMARY                    |            1 | id          | A         |     9943860 |     NULL | NULL   |      | BTREE      |         |               |
        | test_data |          1 | test_data_random_str_index |            1 | random_str  | A         |     9943860 |     NULL | NULL   | YES  | BTREE      |         |               |
        +-----------+------------+----------------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
        2 rows in set (0.00 sec)
        ```

    * Testing with command: `select sum(id) from test_data;`:

        ```
        mysql> select sum(id) from test_data;
        +----------------+
        | sum(id)        |
        +----------------+
        | 50000005000000 |
        +----------------+
        1 row in set (3.28 sec)
        ```

        **Buffer pool infos**
        ```
        mysql> select table_name as Table_Name, index_name as Index_Name, count(*) as Page_Count, sum(data_size)/1024/1024 as Size_in_MB from information_schema.innodb_buffer_page group by table_name, index_name order by Size_in_MB desc limit 5;
        +---------------------------------+----------------------------+------------+--------------+
        | Table_Name                      | Index_Name                 | Page_Count | Size_in_MB   |
        +---------------------------------+----------------------------+------------+--------------+
        | `test_mysql_warmup`.`test_data` | test_data_random_str_index |       7877 | 120.96562290 |
        | `SYS_TABLES`                    | CLUST_IND                  |         86 |   1.20540619 |
        | `SYS_COLUMNS`                   | CLUST_IND                  |          3 |   0.02067661 |
        | `SYS_FIELDS`                    | CLUST_IND                  |          1 |   0.00906658 |
        | `SYS_INDEXES`                   | CLUST_IND                  |          1 |   0.00720882 |
        +---------------------------------+----------------------------+------------+--------------+
        5 rows in set (0.07 sec)
        ```

        => **test_data_random_str_index** is loaded to buffer pool instead of `primary key`, with **7877 pages**

    * Testing with command: `select count(*) from test_data;`:

        ```
        mysql> select count(*) from test_data;
        +----------+
        | count(*) |
        +----------+
        | 10000000 |
        +----------+
        1 row in set (15.43 sec)
        ```
        **Buffer pool info**
        ```
        mysql> select table_name as Table_Name, index_name as Index_Name, count(*) as Page_Count, sum(data_size)/1024/1024 as Size_in_MB from information_schema.innodb_buffer_page group by table_name, index_name order by Size_in_MB desc limit 5;
        +---------------------------------+------------+------------+--------------+
        | Table_Name                      | Index_Name | Page_Count | Size_in_MB   |
        +---------------------------------+------------+------------+--------------+
        | `test_mysql_warmup`.`test_data` | PRIMARY    |       7940 | 106.90351486 |
        | `SYS_TABLES`                    | CLUST_IND  |         86 |   1.20526028 |
        | `SYS_COLUMNS`                   | CLUST_IND  |          3 |   0.02067661 |
        | `SYS_FIELDS`                    | CLUST_IND  |          1 |   0.00906658 |
        | `SYS_INDEXES`                   | CLUST_IND  |          1 |   0.00720882 |
        +---------------------------------+------------+------------+--------------+
        5 rows in set (0.06 sec)
        ```
        => **Primary key** is loaded into buffer pool with **7940 pages**.

    * Testing with command: `select count(*) from test_data where random_str2 = 0 or random_str2 = '0'` (with `random_str2` is `non-index column`):

        ```
        mysql> select count(*) from test_data where random_str2 = '0' or random_str2 = 0;
        | count(*) |
        +----------+
        |        0 |
        +----------+
        1 row in set (14.42 sec)
        ```
        **Buffer pool infos**
        ```
        mysql> select table_name as Table_Name, index_name as Index_Name, count(*) as Page_Count, sum(data_size)/1024/1024 as Size_in_MB from information_schema.innodb_buffer_page group by table_name, index_name order by Size_in_MB desc limit 5;
        +---------------------------------+------------+------------+--------------+
        | Table_Name                      | Index_Name | Page_Count | Size_in_MB   |
        +---------------------------------+------------+------------+--------------+
        | `test_mysql_warmup`.`test_data` | PRIMARY    |       8039 | 108.24720383 |
        | `SYS_TABLES`                    | CLUST_IND  |        147 |   2.08744812 |
        | NULL                            | NULL       |          5 |   0.00000000 |
        +---------------------------------+------------+------------+--------------+
        3 rows in set (0.06 sec)
        ```
        => **Primary key** is loaded with **8039 pages** (greater than **7940 pages**)

# Conclusion:
1. Table with only primary key:
    * `select count(*) from table_name where non_index_column = 0 or non_index_column = '0'` has the greatest pages loaded.
    * `select count(*) from table_name` and `select sum(primary_key) from table_name` has the same result, and the loaded pages is less than query has `where non_index_column = 0 or non_index_column = '0'` condition.

2. Table with primary and other index(es):
    * `select count(*) from table_name`: **primary_key** will be loaded.
    * `select sum(primary_key) from table_name`: **other_index** will be loaded.
    * `select count(*) from table_name where non_index_column = 0 or non_index_column = '0'`: **primary_key** will be loaded with the greatest.



