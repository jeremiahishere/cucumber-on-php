class Database
  def initialize(db)
    @name = db['name']
    @user = db['user']
    @password = db['password']
    @admin_user = db['admin_user']
    @admin_password = db['admin_password']
    # host location
    @host = db['location']
    # name of the database in php
    @var_name = db['var_name']
    # db schema dump
    @schema = db['schema']

    self.drop_create_seed
    @mysql  = Mysql2::Client.new(:host => @host, :username => @user, :password => @password, :database => @name)
  end

  def name
    return @name
  end

  def get_admin_user_info
    admin_user = "-u" + @admin_user
    admin_pass = ""
    admin_pass = "-p" + @admin_password unless @admin_password.empty?
    admin_user_info = admin_user + " " + admin_pass
    return admin_user_info
  end
  
  def drop_create_seed
    puts "Setting up #{@name}"
    admin_user_info = self.get_admin_user_info

    schema_location = File.dirname(__FILE__) + "/db_schemas/" + @schema
    # drop, create, give permissions, seed
    #puts "echo \"DROP DATABASE #{@name};\" | mysql -h#{@host} #{admin_user_info};"
    %x{echo \"DROP DATABASE #{@name};\" | mysql -h#{@host} #{admin_user_info};} 
    #puts "echo \"DROP DATABASE #{@name};\" | mysql -h#{@host} #{admin_user_info};"
    %x{echo \"CREATE DATABASE #{@name};\" | mysql -h#{@host} #{admin_user_info};}
    #puts "echo \"GRANT ALL PRIVILEGES ON #{@name}.* TO #{@user}@#{@host} IDENTIFIED BY '#{@password}'\" | mysql -h#{@host} #{admin_user_info}"
    %x{echo \"GRANT ALL PRIVILEGES ON #{@name}.* TO #{@user}@#{@host} IDENTIFIED BY '#{@password}'\" | mysql -h#{@host} #{admin_user_info}}
    #puts "mysql -h#{@host} -u#{@user} -p#{@password} #{@name} < \"#{schema_location}\";"
    %x{mysql -h#{@host} -u#{@user} -p#{@password} #{@name} < \"#{schema_location}\";}
  end

  def drop
    admin_user_info = self.get_admin_user_info
    %x{echo \"DROP DATABASE #{@name};\" | mysql -h#{@host} #{admin_user_info};}
  end


  # returns a php mysql connect and select db string
  def get_php_connect_info
    return "$#{@var_name} = mysql_connect(\"#{@host}\", \"#{@user}\", \"#{@password}\");\nmysql_selectdb(\"#{@name}\", $#{@var_name});\n"
  end

  # runs a query on the database
  # assumes everything has been escaped
  def query(sql)
    return @mysql.query(sql)
  end

  # escapes the input
  # escape is dependent on the mysql connection object so must be done here
  def escape(input)
    return @mysql.escape(input)
  end
end
