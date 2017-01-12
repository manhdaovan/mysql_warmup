require 'mysql'
module MysqlWarmup
  class Warmer
    ALL_DATABASE      = 'all'.freeze
    EXCLUDE_DATABASES = %w(information_schema mysql performance_schema sys).freeze
    PREVENT_VARIABLES = [:@host, :@username, :@password, :@database, :@port].freeze

    def initialize(host, username, password, port = 3306, database = 'all')
      @host     = host
      @username = username
      @password = password
      @database = database
      @port     = port

      @connector = if warmup_all?
                     Mysql.new(@host, @username, @password, '', @port)
                   else
                     Mysql.new(@host, @username, @password, @database, @port)
                   end
    end

    def warmup
      warmup_all? ? warmup_all_dbs : warmup_only
    end

    # Prevent inspection object
    def inspect
      "#<MysqlWarmup::Warmer:#{object_id}>"
    end

    def instance_variable_get(*several_variants)
      raise 'Not allow to view this variable' if PREVENT_VARIABLES.include?(several_variants[0])
      super
    end

    private

    def warmup_all_dbs
      @connector.list_dbs.each do |db|
        next if EXCLUDE_DATABASES.include?(db)
        MysqlWarmup::Warmer.new(@host, @username, @password, @port, db).warmup
      end
    end

    def warmup_only
      write_log(">>>>>>> START WARMUP FOR DB: #{@database} <<<<<<")
      tables = @connector.query('show tables')
      table  = tables.fetch_row
      while table
        # Fetch fields infos
        fields_infos = fetch_fields_infos(table[0])

        table_instance = MysqlWarmup::Table.new(table[0], fields_infos)
        write_log("START WARMUP FOR TABLE:   `#{@database}`.`#{table[0]}`")
        table_instance.indexes.each do |i|
          touch(i.query_string)
        end
        write_log("SUCCESS WARMUP FOR TABLE: `#{@database}`.`#{table[0]}`\n\n")

        # Continue fetching table
        table = tables.fetch_row
      end
      write_log("+++++++ SUCCESS WARMUP FOR DB: #{@database} +++++++\n\n")
    rescue Mysql::Error => e
      write_log("ERROR: ----------- #{e.message}")
      write_log("BACKTRACE: ------- #{e.backtrace[0, 5]}")
    ensure
      @connector.close if @connector
    end

    def fetch_fields_infos(table_name)
      fields_infos = []
      fields       = @connector.query("describe `#{table_name}`")
      field        = fields.fetch_row
      while field
        fields_infos << field
        field = fields.fetch_row
      end
      fields_infos
    end

    def touch(query_string)
      # write_log(query_string)
      @connector.query(query_string)
    end

    def write_log(log_msg)
      MysqlWarmup::Logger.write(log_msg)
    end

    def warmup_all?
      @database.downcase == ALL_DATABASE
    end
  end
end
