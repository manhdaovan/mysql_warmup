# require File.expand_path(File.dirname(__FILE__), 'mysql_warmup')
require './mysql_warmup'

MysqlWarmup::Warmer.new('localhost', 'root', '123qwe').warmup

# MysqlWarmup::Warmer.new('localhost', 'root', '123qwe', 'uptybt_development').warmup
