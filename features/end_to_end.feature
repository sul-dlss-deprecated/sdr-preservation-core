@deposit
Feature: Deposit an object into Sedora
  In order to deposit an object
  As a depositor
  I want to know that all parts of the ingest workflow are behaving correctly

  Scenario: End to End test
    When I want to test the sedora ingest workflow
    Then I should be able to talk to the workflow service
    #    And I should see a selectable list with field choices
    #    And I should see a "search" button
    #    And I should not see the "startOverLink" element
    #    And I should see "Welcome!"
    #    And I should see a stylesheet

