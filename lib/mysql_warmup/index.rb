module MysqlWarmup
  class Index
    QUERY_TEMPLATE = 'select %s from %s where %s'.freeze
    attr_reader :query_string

    def initialize(table_name, column_name, column_type, column_key, non_index_field = nil)
      @table_name   = table_name
      @column_name  = column_name
      @column_type  = column_type
      @column_key   = column_key
      @query_string = build_query_string(@table_name, @column_name,
                                         @column_type, @column_key, non_index_field)
    end

    private

    def build_query_string(table_name, column_name, column_type, column_key, non_index_field = nil)
      if type_primary?(column_key)
        if non_index_field.nil?
          format_query('count(*)', "`#{table_name}`", '1')
        else
          field_name = "`#{table_name}`.`#{non_index_field}`"
          format_query('count(*)', "`#{table_name}`", "#{field_name} = 0 or #{field_name} = '0'")
        end
      elsif type_integer?(column_type)
        format_query('count(*)', "`#{table_name}`", "`#{table_name}`.`#{column_name}` LIKE '%0%'")
      elsif type_var_char?(column_type)
        format_query('count(*)', "`#{table_name}`", "`#{table_name}`.`#{column_name}` LIKE '%0%'")
      elsif type_blob?(column_type)
        format_query('count(*)', "`#{table_name}`", "`#{table_name}`.`#{column_name}` LIKE '%0%'")
      else
        format_query('count(*)', "`#{table_name}`", "`#{table_name}`.`#{column_name}` LIKE '%0%'")
      end
    end

    def type_primary?(column_key)
      column_key.casecmp('PRI').zero?
    end

    def type_integer?(column_type)
      !(column_type.downcase =~ /int/).nil?
    end

    def type_blob?(column_type)
      !(column_type.downcase =~ /blob/).nil?
    end

    def type_var_char?(column_type)
      !(column_type.downcase =~ /char|varchar|index/).nil?
    end

    def format_query(*params)
      format(QUERY_TEMPLATE, *params)
    end
  end
end
