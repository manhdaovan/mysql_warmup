require 'test/unit'
require 'mysql_warmup'

class TestLogger < Test::Unit::TestCase
  def test_logger_output
    orig_stdout = $stdout
    $stdout     = StringIO.new
    MysqlWarmup::Logger.write('log output')
    assert_equal(true, !($stdout.string =~ /log output/).nil?)
  ensure
    $stdout = orig_stdout
  end
end
