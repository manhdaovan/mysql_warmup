require 'test/unit'
require 'mysql_warmup'

class TestWarmer < Test::Unit::TestCase
  def test_init_and_prevent_variable
    Mysql.class_eval do
      def self.new(*_arg)
        'Mysql Instance'
      end
    end
    warmer = MysqlWarmup::Warmer.new('localhost', 'db_user', 'db_password')
    MysqlWarmup::Warmer::PREVENT_VARIABLES.each do |p_v|
      begin
        warmer.instance_variable_get(p_v)
      rescue => e
        assert_equal('Not allow to view this variable', e.message)
      end
    end
    assert_equal('Mysql Instance', warmer.instance_variable_get(:@connector))
  end
end
