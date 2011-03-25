# debugger
require 'ruby-debug'

# RSpec
require 'rspec/expectations'

# Cucumber setup
require 'capybara/cucumber'
require 'capybara/session'
require 'capybara/mechanize'
require 'cucumber/formatter/unicode'

Capybara.app = "http://test.yoursitehere.com"
Capybara.run_server = false
Capybara.app_host = 'http://test.yoursitehere.com'
Capybara.default_selector = :css
Capybara.default_driver = :mechanize 


require 'test/unit/assertions'
World(Test::Unit::Assertions)

# Be very careful running this on the production server
# The location of the current database connection file 
@database_config_path = File.dirname(__FILE__)+"/../../includes/conn.php"
@original_database_config = File.read(@database_config_path)
@backup_database_config_file = "features/support/conn.php.backup"

# mysql user with permissions to create database and grant permissions
# these have the -u and -p arguments because you get additional dialogues if the mysql root password is blank
@default_mysql_admin_user = "root"
@default_mysql_admin_password = "password"

puts "Loading database information"
# read the database information
@databases = YAML.load(File.open('features/support/database.yml').read)
# iterate over the databases, drop, create and seed, build the mysql_connect statements as well
mysql_connect_output = ""
@databases.each do |db|
  puts "Setting up #{db['name']}"
  admin_user = "-u" + db['admin_user'] ? db['admin_user'] : @default_mysql_admin_user
  admin_pass = db['admin_password'] ? db['admin_password'] : @default_mysql_admin_password
  admin_pass = "-p" + admin_pass unless admin_pass.empty?
  admin_user_info = admin_user + " " + admin_pass

  schema_location = File.dirname(__FILE__) + "/db_schemas/" + db['schema']
  # drop, create, give permissions, seed
  %x{echo \"DROP DATABASE #{db['name']};\" | mysql -h#{db['location']} #{admin_user_info};} 
  %x{echo \"CREATE DATABASE #{db['name']};\" | mysql -h#{db['location']} #{admin_user_info};}
  %x{echo \"GRANT ALL PRIVILEGES ON #{db['name']}.* TO #{db['user']}@#{db['location']} IDENTIFIED BY '#{db['password']}'\" | mysql -h#{db['location']} #{admin_user_info}}
  %x{mysql -h#{db['location']} -u#{db['user']} -p#{db['password']} #{db['name']} < \"#{schema_location}\";}

  mysql_connect_output += "$#{db['var_name']} = mysql_connect(\"#{db['location']}\", \"#{db['user']}\", \"#{db['password']}\");\nmysql_selectdb(\"#{db['name']}\", $#{db['var_name']});\n"
end

# Overwrite the conn file with the new database and authentication 
File.open(@database_config_path, "w") do |file|
  file.puts "
  <?php
  $env = \"test\";
  #{mysql_connect_output}
  ?>
  "
end

# write a backup file for the connection information if a backup file is specified
unless @backup_database_config_file.empty?
  File.open(@backup_database_config_file, "w") do |file|
    file.puts(@original_database_config)
  end
end

def drop_databases
  @databases.each do |db|
    admin_user = "-u" + (db['admin_user'] ? db['admin_user'] : @default_mysql_admin_user)
    admin_pass = (db['admin_password'] ? db['admin_password'] : @default_mysql_admin_password)
    admin_pass = "-p" + admin_pass unless admin_pass.empty?
    admin_user_info = admin_user + " " + admin_pass
    %x{echo \"DROP DATABASE #{db['name']};\" | mysql -h#{db['location']} #{admin_user_info};}
  end
end

# Switch back to whatever was loaded originally
def rollback_to_seed_data
  File.open(@database_config_path, "w") do |file|
    file.puts @original_database_config
  end
end

def remove_backup_config
  %x{rm #{@backup_database_config_file}}
end

at_exit do
  puts "Cleaning up"
  rollback_to_seed_data
  drop_databases
  remove_backup_config
end
