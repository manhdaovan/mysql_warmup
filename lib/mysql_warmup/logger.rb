module MysqlWarmup
  class Logger
    class << self
      def write(log_msg)
        puts "#{Time.now}: --- #{log_msg}"
      end
    end
  end
end
