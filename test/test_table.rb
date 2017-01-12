require 'test/unit'
require 'mysql_warmup'

class TestTable < Test::Unit::TestCase
  def test_indexes_of_table
    table_name  = 'table_name'
    fields_info = [%w(field type null key default extra)] * 5
    table       = MysqlWarmup::Table.new(table_name, fields_info)
    assert_equal(5, table.indexes.size)
    table.indexes.each do |table_index|
      assert_equal(true, table_index.is_a?(MysqlWarmup::Index))
    end
  end
end
