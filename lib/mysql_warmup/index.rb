module MysqlWarmup
  class Index
    def initialize(table_name, column_name, column_type)
      @table_name  = table_name
      @column_name = column_name
      @column_type = column_type
    end

    def build_query_string
      "SELECT COUNT(*) FROM `#{@table_name}`.`#{@column_name}` WHERE `#{@table_name}`.`#{@column_name}` LIKE '%0%'"
    end

    private

    def type_primary?

    end

    
  end
end
