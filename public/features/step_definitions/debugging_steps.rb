When /^I debug$/ do
  debugger
end

When(/^I sleep for ([^"]*) second[s]?$/) do |time|
  sleep(time.to_i)
end

