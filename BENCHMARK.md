# Environment
```
$mysql --version
mysql  Ver 14.14 Distrib 5.7.14, for osx10.11 (x86_64) using  EditLine wrapper
```
CoreI5 @2.6GHz, DDR3 8GB@1600, SSD

# Preparing:

* **A MySQL instance without pre-load buffer pool:**

```
mysql> show variables like '%buffer_pool%';
+-------------------------------------+----------------+
| Variable_name                       | Value          |
+-------------------------------------+----------------+
| innodb_buffer_pool_chunk_size       | 268435456      |
| innodb_buffer_pool_dump_at_shutdown | OFF            |
| innodb_buffer_pool_dump_now         | OFF            |
| innodb_buffer_pool_dump_pct         | 25             |
| innodb_buffer_pool_filename         | ib_buffer_pool |
| innodb_buffer_pool_instances        | 1              |
| innodb_buffer_pool_load_abort       | OFF            |
| innodb_buffer_pool_load_at_startup  | OFF            |
| innodb_buffer_pool_load_now         | OFF            |
| innodb_buffer_pool_size             | 268435456      |
+-------------------------------------+----------------+
10 rows in set (0.00 sec)
```

* **A table with structure:**

```
mysql> desc test_data;
+-------------+--------------+------+-----+---------+----------------+
| Field       | Type         | Null | Key | Default | Extra          |
+-------------+--------------+------+-----+---------+----------------+
| id          | int(11)      | NO   | PRI | NULL    | auto_increment |
| random_str  | varchar(255) | YES  | MUL | NULL    |                |
| random_str2 | varchar(255) | YES  |     | NULL    |                |
+-------------+--------------+------+-----+---------+----------------+
3 rows in set (0.00 sec)
```

* **10M rows data:**

```
mysql> select count(*) from test_data;
+----------+
| count(*) |
+----------+
| 10000000 |
+----------+
1 row in set (8.38 sec)
```

* **A file contains 20k queries with unique key, with format:**

```
select * from test_data where random_str = "unique_string_value";
```

with `unique_string_value` is one of 10M `random_str`, and 20k of `unique_string_value` is totally difference.

# Scenario

* **Step0: Start MySQL with command:**

```
$mysql.server start --innodb_buffer_pool_load_at_startup=0 --innodb_buffer_pool_dump_at_shutdown=0 --innodb_buffer_pool_chunk_size=256M --innodb_buffer_pool_size=256M
```

* **Step1: Run benchmark command without running mysql-warmup tool before request:**

```
$mysqlslap --create-schema=warmup_benchmark --delimiter=";" --query=benchmark_query_20000_rows.sql --concurrency=1 --iterations=1 -uroot -p
Enter password:
Benchmark
	Average number of seconds to run all queries: 7.562 seconds
	Minimum number of seconds to run all queries: 7.562 seconds
	Maximum number of seconds to run all queries: 7.562 seconds
	Number of clients running queries: 1
	Average number of queries per client: 20001

```

* **Step2: Run same command test immediately, to compare when all key was hit on buffer pool:**

```
$mysqlslap --create-schema=warmup_benchmark --delimiter=";" --query=benchmark_query_20000_rows.sql --concurrency=1 --iterations=1 -uroot -p
Enter password:
Benchmark
	Average number of seconds to run all queries: 1.740 seconds
	Minimum number of seconds to run all queries: 1.740 seconds
	Maximum number of seconds to run all queries: 1.740 seconds
	Number of clients running queries: 1
	Average number of queries per client: 20001
```

* **Step 3: Stop mysql, restart machine, then start MySQL service same as Step0.**

* **Step4: Run mysql-benchmark tool:**

```
$mysql-warmup -uroot -dwarmup_benchmark

Input the mysql password:
my_mysql_root_password
2017-02-24 15:33:07 +0900: --- >>>>>>> START WARMUP FOR DB: warmup_benchmark <<<<<<
2017-02-24 15:33:07 +0900: --- START WARMUP FOR TABLE:   `warmup_benchmark`.`test_data`
2017-02-24 15:33:29 +0900: --- SUCCESS WARMUP FOR TABLE: `warmup_benchmark`.`test_data`

2017-02-24 15:33:29 +0900: --- +++++++ SUCCESS WARMUP FOR DB: warmup_benchmark +++++++
```

* **Step5: Run benchmark command same as Step1:**

```
$mysqlslap --create-schema=warmup_benchmark --delimiter=";" --query=benchmark_query_20000_rows.sql --concurrency=1 --iterations=1 -uroot -p
Enter password:
Benchmark
	Average number of seconds to run all queries: 2.132 seconds
	Minimum number of seconds to run all queries: 2.132 seconds
	Maximum number of seconds to run all queries: 2.132 seconds
	Number of clients running queries: 1
	Average number of queries per client: 20001
```

* **Step6: Run same command test immediately, to compare when all key was hit on buffer pool:**

```
$mysqlslap --create-schema=warmup_benchmark --delimiter=";" --query=benchmark_query_20000_rows.sql --concurrency=1 --iterations=1 -uroot -p
Enter password:
Benchmark
	Average number of seconds to run all queries: 1.886 seconds
	Minimum number of seconds to run all queries: 1.886 seconds
	Maximum number of seconds to run all queries: 1.886 seconds
	Number of clients running queries: 1
	Average number of queries per client: 20001
```

# Conclusion:

* The main point is results in **Step1** and **Step5**. **7.562 seconds** vs **2.132 seconds** for first hits. Nice.
* Other point is results in **Step2** and **Step6**. **1.740 seconds** vs **1.886 seconds**.
Why?<br/>
 In **Step1**, only 20k indexes by test queries were loaded into buffer. So, when **Step2** runs, exactly 20k indexes were hit.<br/>
 But in **Step5**, all of 10M indexes were loaded (by running mysql-warmup tool). So, when **Step6** runs, it needed to find 20k indexes among 10M indexes.





