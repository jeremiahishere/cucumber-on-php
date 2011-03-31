def generate_time_id
  now = Time.now
  # 2011-02-29 12:12:43 12
  return now.strftime("%Y%m%d%H%M%S") + now.usec.to_s
end

def generate_id_for_table(table_name, id_field)
  id = generate_time_id
  count = @@dbm.query("select count(*) as count from #{table_name} where #{id_field}=#{id}").first['count']
  if count > 1
    return generate_id_for_table(table_name, id_field)
  else
    return id
  end
end

def get_last_entry_id(table, id_col)
  @@dbm.query("select #{id_col} from #{table} order by #{id_col} desc limit 1").first[id_col]
end

Given /^an entry in (.*)(?: using database (.*))? exists with the following attributes:$/ do |table_name, db_name, values_table|
  query_sql = ""
  values_table.raw.each do |pair|
    if query_sql.empty?
      # The mysql escape is more for handling input with single quotes and less for stopping injections
      query_sql = "insert into #{table_name} set #{pair[0]}='#{@@dbm.escape(pair[1])}'"
    else
      query_sql += ", #{pair[0]}='#{pair[1]}'"
    end
  end
  if db_name
    @@dbm.query(query_sql, db_name)
  else
    @@dbm.query(query_sql)
  end
end

Given /^there are no entries in (.*)(?: using database (.*))?$/ do |table_name, db_name|
  if db_name
    @@dbm.query("delete from #{table_name}", db_name)
  else
    @@dbm.query("delete from #{table_name}")
  end
end
  
