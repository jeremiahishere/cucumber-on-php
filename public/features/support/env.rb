# debugger
require 'ruby-debug'

# RSpec
require 'rspec/expectations'

# Cucumber setup
require 'capybara/cucumber'
require 'capybara/session'
require 'capybara/mechanize'
require 'cucumber/formatter/unicode'

# database
require 'mysql2'
require File.dirname(__FILE__) + '/database.rb'
require File.dirname(__FILE__) + '/database_manager.rb'

Capybara.app = "http://test.yoursitehere.com"
Capybara.run_server = false
Capybara.app_host = 'http://test.yoursitehere.com'
Capybara.default_selector = :css
Capybara.default_driver = :mechanize
Capybara.javascript_driver = :selenium


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
@default_mysql_admin_password = ""

puts("Loading database information")
@@dbm = DatabaseManager.new(@default_mysql_admin_user, @default_mysql_admin_password)
# read the database information
@databases = YAML.load(File.open('features/support/database.yml').read)
@databases.each do |db|
  @@dbm.add_database(db)
end
mysql_connect_output = @@dbm.get_php_connect_info

puts("Writing conn file")
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
  @@dbm.drop_all_databases
end

# Switch back to whatever was loaded originally
def rollback_to_seed_data
  File.open(@database_config_path, "w") do |file|
    file.puts @original_database_config
  end
end

def remove_backup_config
  %x{rm -f #{@backup_database_config_file}}
end

at_exit do
  print("Cleaning up")
  rollback_to_seed_data
  drop_databases
  remove_backup_config
end
