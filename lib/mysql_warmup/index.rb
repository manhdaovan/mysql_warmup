module MysqlWarmup
  class Index
    QUERY_TEMPLATE = 'select %s from %s where %s'
    attr_reader :query_string

    def initialize(table_name, column_name, column_type, column_key)
      @table_name   = table_name
      @column_name  = column_name
      @column_type  = column_type
      @column_key   = column_key
      @query_string = build_query_string(@table_name, @column_name, @column_type, @column_key)
    end

    private

    def build_query_string(table_name, column_name, column_type, column_key)
      if type_primary?(column_key) && type_integer?(column_type)
        QUERY_TEMPLATE % ["sum(`#{table_name}`.`#{column_name}`)", "`#{table_name}`", '1']
      elsif type_integer?(column_type)
        QUERY_TEMPLATE % ['count(*)', "`#{table_name}`", "`#{table_name}`.`#{column_name}` LIKE '%0%'"]
      elsif type_var_char?(column_type)
        QUERY_TEMPLATE % ['count(*)', "`#{table_name}`", "`#{table_name}`.`#{column_name}` LIKE '%0%'"]
      elsif type_blob?(column_type)
        QUERY_TEMPLATE % ['count(*)', "`#{table_name}`", "`#{table_name}`.`#{column_name}` LIKE '%0%'"]
      else
        QUERY_TEMPLATE % ['count(*)', "`#{table_name}`", "`#{table_name}`.`#{column_name}` LIKE '%0%'"]
      end
    end

    def type_primary?(column_key)
      column_key.upcase == 'PRI'
    end

    def type_integer?(column_type)
      !(column_type.downcase =~ /int/).nil?
    end

    def type_blob?(column_type)
      !(column_type.downcase =~ /blob/).nil?
    end

    def type_var_char?(column_type)
      !(column_type.downcase =~ /varchar|index/).nil?
    end
  end
end
