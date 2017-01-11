module MysqlWarmup
  class Table
    DESC_TABLE_STRUCTURE = {
      field:   0,
      type:    1,
      null:    2,
      key:     3,
      default: 4,
      extra:   5
    }.freeze

    attr_reader :indexes

    def initialize(table_name, field_infos)
      @table_name  = table_name
      @field_infos = field_infos
      @indexes     = build_index
    end

    private

    def build_index
      indexes_infos = @field_infos.select { |v| !v[DESC_TABLE_STRUCTURE[:key]].empty? }
      indexes       = []
      indexes_infos.each do |index_info|
        indexes << MysqlWarmup::Index.new(@table_name,
                                          index_info[DESC_TABLE_STRUCTURE[:field]],
                                          index_info[DESC_TABLE_STRUCTURE[:type]])
      end
      indexes
    end
  end
end
