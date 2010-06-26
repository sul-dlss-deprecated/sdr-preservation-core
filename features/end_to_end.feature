@deposit
Feature: Deposit an object into Sedora
  In order to deposit an object
  As a depositor
  I want to know that all parts of the ingest workflow are behaving correctly

  Scenario: End to End test

	# ##################################################
	# Initial setup
	When I want to test the sedora ingest workflow
    Then I should be able to talk to the workflow service
 	And I should be able to create a new object in DOR for testing against
	# note: ingest-deposit is going to become sdr-ingest-transfer 
 	And that object should have a "googleScannedBookWF" state where "ingest-deposit" is "completed"
 	And that object should have a "googleScannedBookWF" state where "register-sdr" is "waiting"
 	
	# ##################################################
	# Robot 1: register-sdr
	When I run the robot "GoogleScannedBook::RegisterSdr" for the "register-sdr" step of the "googleScannedBook" workflow
	Then that object should exist in SEDORA
	And it should have a SEDORA workflow datastream where "register-sdr" is "completed"
	And it should have a SEDORA workflow datastream where "transfer-object" is "waiting"
	
	# ##################################################
	# Robot 2: transfer-object 
	When I run the robot "SdrIngest::TransferObject" for the "transfer-object" step of the "sdrIngest" workflow
	Then there should be a properly named bagit object in SDR_DEPOSIT_DIR
	And it should have a SEDORA workflow datastream where "transfer-object" is "completed"  
	And it should have a SEDORA workflow datastream where "validate-bag" is "waiting"
	
	# ##################################################
	# Robot 3: validate-bag
	When I run the robot "SdrIngest::ValidateBag" for the "validate-bag" step of the "sdrIngest" workflow
	Then it should have a SEDORA workflow datastream where "validate-bag" is "error"  
	And it should have a SEDORA workflow datastream where "populate-metadata" is "waiting"
	And when I explicitly set "validate-bag" to "completed"
	Then it should have a SEDORA workflow datastream where "validate-bag" is "completed"  
	
	# ##################################################
	# Robot 4: populate-metadata
	When I run the robot "SdrIngest::PopulateMetadata" for the "populate-metadata" step of the "sdrIngest" workflow
	Then it should have a SEDORA workflow datastream where "populate-metadata" is "completed"  
	And it should have a SEDORA workflow datastream where "verify-agreement" is "waiting"
	
	# ##################################################
	# Robot 5: verify-agreement
	When I run the robot "SdrIngest::VerifyAgreement" for the "verify-agreement" step of the "sdrIngest" workflow
	 # because it isn't working yet
	Then it should have a SEDORA workflow datastream where "verify-agreement" is "waiting"
	And when I explicitly set "verify-agreement" to "completed"
	Then it should have a SEDORA workflow datastream where "verify-agreement" is "completed"
	And it should have a SEDORA workflow datastream where "complete-deposit" is "waiting"
	
	# ##################################################
	# Robot 6: complete-deposit
	When I run the robot "SdrIngest::VerifyAgreement" for the "verify-agreement" step of the "sdrIngest" workflow
	
