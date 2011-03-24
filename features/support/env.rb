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

# Helper method for running shell commands
def run(command, message = nil, verbose = true)
  if verbose then
    puts "#{message}"
    puts command
    result = `#{command}`
    puts result
    return result
  else
    `#{command}`
  end
end

# Be very careful running this on the production server
# The location of the current database connection file 
@database_config_path = File.dirname(__FILE__)+"/../../includes/conn.php"
@original_database_config = File.read(@database_config_path)

# mysql doesn't automatically link on osx.
# Change as necessary
if RUBY_PLATFORM.downcase.include?('darwin')
  @@mysql = "/usr/local/mysql-5.1.53-osx10.6-x86_64/bin/mysql" 
else
  @@mysql = "mysql" 
end

# mysql user with permissions to create database and grant permissions
# these have the -u and -p arguments because you get additional dialogues if the mysql root password is blank
@@mysql_admin_user = "-u" + "root"
@@mysql_admin_password = "-p" + "password"

# database location and name
@@test_database_location = "localhost"
@@test_database_name = "yoursitehere_test_db"

# mysql user used in the conn file
@@test_database_username = "root"
@@test_database_password = "password"

# Path for the db dump used to seed the tests
@path_to_seed_data = File.dirname(__FILE__)+"./db/dumps/yoursitehere_db_dump.sql"

# Overwrite the conn file with the new database and authentication 
File.open(@database_config_path, "w") do |file|
  file.puts "
  <?php
  $env = \"test\";
  $MAIN_CONN = mysql_connect(\"#{@@test_database_location}\",\"#{@@test_database_username}\",\"#{@@test_database_password}\");
  mysql_selectdb(\"#{@@test_database_name}\", $MAIN_CONN);
  ?>
  "
end

# Optional check to see if test database exists, if not create the user p
# could be useful if drop, create, seed takes too long
# unless(run("echo \"SHOW DATABASES;\" | mysql -u #{@@test_database_username} --password=#{@@test_database_password} 2>&1").match @@test_database_name ) then

# drop the test database
run("echo \"DROP DATABASE #{@@test_database_name};\" | #{@@mysql} #{@@mysql_admin_user} #{@@mysql_admin_password};", "Dropping test database")
# add the test database
run("echo \"CREATE DATABASE #{@@test_database_name};\" | #{@@mysql} #{@@mysql_admin_user} #{@@mysql_admin_password};", "Creating test database")
# add privileges to the test database
run("echo \"GRANT ALL PRIVILEGES ON #{@@test_database_name}.* TO #{@@test_database_username}@#{@@test_database_location} IDENTIFIED BY '#{@@test_database_password}'\" | #{@@mysql} #{@@mysql_admin_user} #{@@mysql_admin_password}", "Adding test user privileges to database")
# seed test database
run("#{@@mysql} -u#{@@test_database_username} -p#{@@test_database_password} #{@@test_database_name} < \"#{@path_to_seed_data}\";", "Seeding database")

# setup display for selenium tests using xvfb
# puts "Cucumber test with Xvfb and firefox"
ENV['DISPLAY'] = ":99"
run("Xvfb :99 -ac -screen 0 1024x768x16 2>/dev/null >/dev/null &", "Setup xvfb on display 99")
run("firefox --display=:99 2>/dev/null >/dev/null &", "Launch firefox on display 99")



# Switch back to whatever was loaded originally
def rollback_to_seed_data
  File.open(@database_config_path, "w") do |file|
    file.puts @original_database_config
  end

  run("echo \"DROP DATABASE #{@@test_database_name};\" | #{@@mysql} #{@@mysql_admin_user} #{@@mysql_admin_password};", "Dropping test database")

  run("killall Xvfb")
  run("killall firefox")

  # puts "Cucumber finished, Resetting test database"
  # run "mysql -u #{@@test_database_username} --password=#{@@test_database_password} #{@@test_database_name} < #{@path_to_seed_data}"
end

at_exit do
  rollback_to_seed_data
end
