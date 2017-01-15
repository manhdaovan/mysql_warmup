require 'test/unit'
require 'mysql_warmup'
require 'helper'

class TestIndex < Test::Unit::TestCase
  def test_query_string
    types = %w(VARCHAR TEXT BLOB INT DATE OTHERS)
    # Index for primary
    # 1. without any non-index field
    index = MysqlWarmup::Index.new('table_name', 'col_name', 'INT', 'PRI')
    assert_equal(build_query('count(*)', '`table_name`', '1'),
                 index.query_string)
    # 2. with non-index field
    index2 = MysqlWarmup::Index.new('table_name', 'col_name', 'INT', 'PRI', 'non_index')
    field_name = '`table_name`.`non_index`'
    assert_equal(build_query('count(*)', '`table_name`', "#{field_name} = 0 or #{field_name} = '0'"),
                 index2.query_string)

    # Index for other fields
    types.each do |type|
      index = MysqlWarmup::Index.new('table_name', 'col_name', type, '')
      assert_equal(build_query('count(*)', '`table_name`', "`table_name`.`col_name` LIKE '%0%'"),
                   index.query_string)
    end
  end
end
