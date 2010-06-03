@deposit
Feature: Deposit an object into Sedora
  In order to deposit an object
  As a depositor
  I want to know that all parts of the ingest workflow are behaving correctly

  Scenario: End to End test
    When I want to test the sedora ingest workflow
    Then I should be able to talk to the workflow service
	And I should be able to create a new object in DOR for testing against
	# And that object should have a "googleScannedBookWF" state where "ingest-deposit" is "completed" and "register-sdr" is "waiting"
	# 
	# When I run the ingest robot
	# Then that object should exist in SEDORA
	# And it should have a SEDORA workflow datastream where "ingest" is "completed" and "transfer" is "waiting"
	# 
	# When I run the transfer robot
	# Then there should be a properly named bagit object in SEDORA_DROPOFF
	# And it should have a SEDORA workflow datastream where "transfer" is "completed" and "populate-metadata" is "waiting"
	# 
	# When I run the populate-metadata robot
	# Then the object should have a metadata datastream
	# And it should have an identity datastream
	# And it should have a provenance datastream
	# And it should have a SEDORA workflow datastream where "populate-metadata" is "completed" and "??" is "waiting"
	# 
	

