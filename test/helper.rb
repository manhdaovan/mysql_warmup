def query_template
  'select %s from %s where %s'.freeze
end

def build_query(*params)
  format(query_template, *params)
end
