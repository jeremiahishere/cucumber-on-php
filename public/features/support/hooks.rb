AfterStep('@debug') do |scenario|
  puts current_url
end

After do |scenario|
  @@dbm.databases.each do |db|
    @@dbm.query("show tables where Table_Type='BASE TABLE'", db).each do |t|
      # tables are in a hash that returns an array when you get first
      # no idea why
      table = t.first[1]
      @@dbm.query("delete from #{table}", db)
    end
  end
end
