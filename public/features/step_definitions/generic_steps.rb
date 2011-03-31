# 3-29-2011: this feels really fragile but I think will work for now
When /^I follow "([^"]*)" for the current entry in (.*)(?: identified by "([^"]*)")?$/ do |action, table, id_col|
  # default id column is 'id'
  if id_col.nil?
    id_col = "id"
  end
  follow_specified_anchor(action, table, id_col).click
end

When /^I should not see anchor "([^"]*)" for the current entry in (.*)(?: identified by "([^"]*)")?$/ do |action, table, id_col|
  # default id column is 'id'
  if id_col.nil?
    id_col = "id"
  end
  follow_specified_anchor(action, table, id_col).should be_nil
end

def follow_specified_anchor(action, table, id_col)
  # assume tables are namespaced
  namespace = table.split("_").first
  # assume manager name corresponds to table name
  # assume the table is plural ending in s or es, no support for nonstandard plurals because I don't have access to singularize
  manager = table.gsub(namespace + "_", "")
  if manager[-2..-1] == "es"
    manager = manager[0..-3]
  elsif manager [-1..-1] == "s"
    manager = manager[0..-2]
  end
  id = @@dbm.query("select #{id_col} from #{table} order by #{id_col} desc limit 1").first[id_col]
  begin
    return find(:xpath, "//a[@href = '/#{namespace}/#{manager}#{action}.php?#{id_col}=#{id}']")
  rescue Capybara::ElementNotFound => e
    return nil
  end
end

When /^I follow the redirect$/ do
  page.driver.response.redirect?.should be_true
  page.driver.follow_redirect!
end

Then /^show me the page$/ do
  puts "HERE IS THE PAGE"
  puts  page.body
  #save_and_open_page
end

# tests if fckeditor is working by trying to write to it
# must be run with @javascript
When /^I fill in "([^"]*)" in the FCKEditor instance "([^"]*)"$/ do |value, editor_field_id|
  browser = page.driver
  browser.execute_script("FCKeditorAPI.GetInstance('#{editor_field_id}').SetHTML('#{value}');")
end

When /^there is no FCKEditor instance "([^"]*)"$/ do |editor_field_id|
  begin
    browser = page.driver
    browser.execute_script("FCKeditorAPI.GetInstance('#{editor_field_id}').SetHTML('test string');")
    assert false
  rescue Selenium::WebDriver::Error::UnexpectedJavascriptError => e
    assert true
  end  
end

Then /^(?:|I )am specifically on path "([^"]*)"(?: for the current entry in "([^"]*)"(?: identified by "([^"]*)")?)?$/ do |page_name, table_name, id_col|
  # method that sends the given page name through the paths.rb file then strips off the url
  if table_name
    if id_col.nil?
      id_col = "id"
    end
    id = get_last_entry_id(table_name, id_col).to_s
    page_name = page_name + "?" + id_col + "=" + id
  end

  page_name = "path \"" + page_name + "\""
  visit path_to(page_name)
end

Then /^everything should be fine and dandy$/ do
end

