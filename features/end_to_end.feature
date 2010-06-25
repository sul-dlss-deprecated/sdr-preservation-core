@deposit
Feature: Deposit an object into Sedora
  In order to deposit an object
  As a depositor
  I want to know that all parts of the ingest workflow are behaving correctly

  Scenario: End to End test
   When I want to test the sedora ingest workflow
    Then I should be able to talk to the workflow service
 	And I should be able to create a new object in DOR for testing against
# note: ingest-deposit is going to become sdr-ingest-transfer 
 	And that object should have a "googleScannedBookWF" state where "ingest-deposit" is "completed"
 	And that object should have a "googleScannedBookWF" state where "register-sdr" is "waiting"
 	
	
	When I run the robot "GoogleScannedBook::RegisterSdr" for the "register-sdr" step of the "googleScannedBook" workflow
	Then that object should exist in SEDORA
	And it should have a SEDORA workflow datastream where "register-sdr" is "completed"
	And it should have a SEDORA workflow datastream where "transfer-object" is "waiting"
	
	When I run the robot "SdrIngest::TransferObject" for the "transfer-object" step of the "sdrIngest" workflow
	# Then there should be a properly named bagit object in SEDORA_DROPOFF
	# Then it should have a SEDORA workflow datastream where "transfer" is "completed"
	# And it should have a SEDORA workflow datastream where "populate-metadata" is "waiting"
	
	# 
	# When I run the populate-metadata robot
	# Then the object should have a metadata datastream
	# And it should have an identity datastream
	# And it should have a provenance datastream
	# And it should have a SEDORA workflow datastream where "populate-metadata" is "completed" and "??" is "waiting"
	# 
	

