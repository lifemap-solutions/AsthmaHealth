Feature: Activity Completion

Scenario: Completing daily survey should be reflected on dashboard Activity Completion
  Given I am Signed in as Asthma user
  And I navigate to "Dashboard"
  Then Activity Completion percentage is "0%"
  And I navigate to "Activities"
  And I have 5 todays tasks
  When I complete daily survey with answers
  |day_symptoms|night_symptoms|use_qr|quick_relief_puffs|get_worse|peakflow|medicine|
  |Yes         |Yes           |Yes   |13                |A cold   |65      |Yes, all of my prescribed doses|
  And I navigate to "Dashboard"
  Then Activity Completion percentage is "20%"
