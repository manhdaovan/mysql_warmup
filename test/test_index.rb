require 'test/unit'
require 'mysql_warmup'
require 'helper'

class TestIndex < Test::Unit::TestCase
  def test_query_string
    types = %w(VARCHAR TEXT BLOB INT DATE OTHERS)
    # Index for primary
    index = MysqlWarmup::Index.new('table_name', 'col_name', 'INT', 'PRI')
    assert_equal(build_query('sum(`table_name`.`col_name`)', '`table_name`', '1'),
                 index.query_string)

    # Index for other fields
    types.each do |type|
      index = MysqlWarmup::Index.new('table_name', 'col_name', type, '')
      assert_equal(build_query('count(*)', '`table_name`', "`table_name`.`col_name` LIKE '%0%'"),
                   index.query_string)
    end
  end
end
