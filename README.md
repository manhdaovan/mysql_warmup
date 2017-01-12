# mysql_warmup
Simple mysql-wamup command tool for warming up mysql server after create/reboot
[Github](https://github.com/manhdaovan/mysql_warmup)

# Background
With InnoDB storage engine, when you've just created new slave instance,
first requests to DB will be hit on disk instead of buffer poll. So, the requests will be slow down.
You can use this tool for warming up buffer poll before the first requests come.
[Detail](https://www.percona.com/blog/2008/05/01/quickly-preloading-innodb-tables-in-the-buffer-pool/)

# Usage
1. **When?**
  * You've set up new slave instance (base on Master-Slave model)
  * Your mysql version < 5.6, that not support [Saving and Restoring the Buffer Pool State](https://dev.mysql.com/doc/refman/5.6/en/innodb-preload-buffer-pool.html), and your mysql instance just reboot
  * Your mysql version >= 5.6, but you not config [Saving and Restoring the Buffer Pool State](https://dev.mysql.com/doc/refman/5.6/en/innodb-preload-buffer-pool.html), and your mysql just reboot
2. **How?**
  * Install this tool (please see `Install` section below)
  * Usage as below syntax

```
    Usage: mysql-warmup -h host-or-ip -u username <options>

    Input options:
    -h host      : Host or ip of mysql instance
    -u username  : Username to access mysql instance
    -d database  : Database to warmup.
                   Default to all databases exclude information_schema, mysql, performance_schema, sys
    -p port      : Port to connect. Default to 3306
    --help       : Show help message
    --version    : Show mysql-warmup version
```

# Install
* Directly with command: `$gem install mysql-warmup`

* Or with `Gemfile` by adding line '`gem 'mysql-warmup`' to your `Gemfile` then `$bundle install`

# TODO
* RDoc

# Development
* All PR are welcome.
* Be sure all test cases are passed by command: `$rake test`

