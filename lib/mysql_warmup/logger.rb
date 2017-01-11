module MysqlWarmup
  class Logger
    class << self
      def write(log_msg)
        puts log_msg
      end
    end
  end
end
