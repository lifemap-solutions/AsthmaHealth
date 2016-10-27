Feature: Data Correlation

Scenario: Initial Correlations is between “Average daily steps” and “Peak Flow"
  Given I am Signed in as Asthma user
  And I navigate to "Dashboard"
  Then I can see "Data Correlations" graph
  Then "Data Correlations" data sets are "Steps" and "Peak Flow"

Scenario: User can choose data correlations between : “Average daily steps”, “Peak Flow”, “Rescue inhaler puffs”, “Controller medicine adherence”
  Given I am Signed in as Asthma user
  And I navigate to "Dashboard"
  Then I can see "Data Correlations" graph

  When I tap the "Series1" data set title
  Then I can see Data Correlations selections view for "Series 1"
  When I choose "Rescue Inhaler puffs"
  Then I go back
  Then "Data Correlations" data sets are "Rescue Inhaler puffs" and "Peak Flow"

  When I tap the "Series1" data set title
  Then I can see Data Correlations selections view for "Series 1"
  When I choose "Controller Medicine Adherence"
  Then I go back
  Then "Data Correlations" data sets are "Controller Medicine Adherence" and "Peak Flow"

  When I tap the "Series2" data set title
  Then I can see Data Correlations selections view for "Series 2"
  When I choose "Steps"
  Then I go back
  Then "Data Correlations" data sets are "Controller Medicine Adherence" and "Steps"

  When I tap the "Series2" data set title
  Then I can see Data Correlations selections view for "Series 2"
  When I choose "Peak Flow"
  Then I go back
  Then "Data Correlations" data sets are "Controller Medicine Adherence" and "Peak Flow"

  When I tap the "Series2" data set title
  Then I can see Data Correlations selections view for "Series 2"
  When I choose "Rescue Inhaler puffs"
  Then I go back
  Then "Data Correlations" data sets are "Controller Medicine Adherence" and "Rescue Inhaler puffs"