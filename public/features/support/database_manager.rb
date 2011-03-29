class DatabaseManager

  def initialize(default_admin_user, default_admin_password)
    @default_admin_user = default_admin_user
    @default_admin_password = default_admin_password
    # list of databases that can be queried
    @dbs = Hash.new
    # default database name
    # set if db['default'] is true and defaults to the first database read
    # usage: @dbs[@default_db_name]
    @default_db_name = ""
  end

  def add_database(db)
    if !db['admin_user']
      db['admin_user'] = @default_admin_user
    end
    if !db['admin_password'] 
      db['admin_password'] = @default_admin_password
    end
    if db['default'] || @default_db_name.empty?
      @default_db_name = db['name']
    end
    @dbs[db['name']] = Database.new(db)
  end

  # this is handled through the database class
  # calling it may cause issues with mysql connections there
  def setup_all_databases
    @dbs.each_value do |db|
      @dbs.drop_create_seed
    end
  end

  def drop_all_databases
    @dbs.each_value do |db|
      db.drop
    end
  end

  # returns the php connect information with the default database last
  def get_php_connect_info
    output = ""
    @dbs.each_value do |db|
      if db.name != @default_db_name
        output += db.get_php_connect_info
      end
    end
    output += @dbs[@default_db_name].get_php_connect_info
    return output
  end

  # queries the specified database
  def query(db_name, sql)
    if @dbs.has_key?(db_name)
      return @dbs[db_name].query(sql) 
    else
      puts "The database #{db_name} does not exist in the database manager"
    end
  end

  # queries the default database
  def query_default(sql)
    return self.query(@default_db_name, sql)
  end
end
