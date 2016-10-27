Given /^I am Signed in as Asthma user$/ do
  @user = User.new(self, 'ui_automation@yopmail.com', 'ui_automation').signIn()
end

When /^I complete daily survey with answers$/ do |answers|
  wait_for_none_animating()
  touch("view marked:'Daily Survey'")
  TaskHandler.new(self,answers.raw).completeTask()
  wait_for_none_animating()
end

And /^I navigate to "([^\"]*)"$/ do |tabBarItem|
  #wait_for_none_animating()
  touch("view marked:'#{tabBarItem}'")
end

And /^I have (\d+) todays tasks$/ do |expectedTaskCount|
  wait_for_none_animating()
  taskCount = query('tableView', numberOfRowsInSection:0)[0]
  expect(taskCount).to eq(expectedTaskCount.to_i)
end

Then /^Activity Completion percentage is "([^\"]*)"$/ do |expectedPercentage|
  wait_for_elements_exist(["view:'APCCircularProgressView'"], :timeout => 6)
  label = query("view:'APCCircularProgressView' label")[0]
  currentPercentage = label['value']
  expect(currentPercentage).to eq(expectedPercentage)
end

Then /^"([^\"]*)" data sets are "([^\"]*)" and "([^\"]*)"$/ do |dashboardItem, series1, series2|
  series1Label = query("button marked:'Series1' label")[0]
  series1Text = series1Label['value']
  expect(series1Text).to eq(series1)
  series2Label = query("button marked:'Series2' label")[0]
  series2Text = series2Label['value']
  expect(series2Text).to eq(series2)
end

Then /^I can see "([^\"]*)" graph$/ do |dashboardItem|
  wait_poll(:until_exists => "label text:'#{dashboardItem}'", :timeout => 6) do
    scroll("tableView", :down)
  end
end

When /^I tap the "([^\"]*)" data set title$/ do |seriesButtonIdentifier|
  wait_for_none_animating()
  touch("button marked:'#{seriesButtonIdentifier}'")
end

Then /^I can see Data Correlations selections view for "([^\"]*)"$/ do |series|
  wait_for_none_animating()
  headerViewTitle = query("view:'UITableViewHeaderFooterView' label", :text)[0]
  expect("Select #{series}").to eq(headerViewTitle)
end

When /^I choose "([^\"]*)"$/ do |selectionItem|
  touch("view marked:'#{selectionItem}'")
end




