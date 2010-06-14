require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'rubygems'
require 'lyber_core'
require 'sdrIngest/complete_deposit'


describe SdrIngest::CompleteDeposit do
  
  def setup
    @complete_robot = SdrIngest::CompleteDeposit.new("sdrIngest","complete-deposit")    
    @complete_robot.bag_directory = SDR2_EXAMPLE_OBJECTS

    mock_workitem = mock("complete_deposit_workitem")
    mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")    
    
    Fedora::Repository.register(SEDORA_URI)
    ActiveFedora::SolrService.register(SOLR_URL)
    
    # Make sure we're starting with a blank object
    begin
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)
      obj.delete
    rescue
      $stderr.print $!
    end
    
    begin
      obj = ActiveFedora::Base.new(:pid => mock_workitem.druid)
      obj.save
    rescue
      $stderr.print $!
    end
  end

  def cleanup
    mock_workitem = mock("complete_deposit_workitem")
    mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")

    Fedora::Repository.register(SEDORA_URI)
    ActiveFedora::SolrService.register(SOLR_URL)
    
    # Make sure we're starting with a blank object
    begin
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)
      obj.delete
    rescue
      $stderr.print $!
    end

  end
  
  context "basic behavior" do
    it "should be able to process a work item" do
      complete_robot = SdrIngest::CompleteDeposit.new("sdrIngest","complete-deposit")          
      complete_robot.should respond_to(:process_item)
    end
  end
    
  context "can load Sedora object with corresponding druid" do
    before(:each) do
      setup
    end
    
    after(:each) do
      cleanup
    end
    
    it "has an accessor method for obj" do
      @complete_robot.should respond_to(:obj)
    end
    
    it "should load a Sedora object with the corresponding druid" do     
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
      
      @complete_robot.process_item(mock_workitem)
      
      @complete_robot.obj.should be_instance_of(ActiveFedora::Base)
      @complete_robot.obj.pid.should eql(mock_workitem.druid) 
    end
    
    it "should raise an error if the Sedora obj with corresponding druid cannot be loaded" do
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return("druid:123")
      
      lambda {@complete_robot.process_item(mock_workitem)}.should raise_error(/Sedora/)
    end  
  end

  context "Update provenance" do
    before(:each) do
      setup
    end
    
    after(:each) do
      cleanup
    end

    it "should raise error if update provenance fails" do
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      @complete_robot.stub!(:update_provenance).and_return(false)
      lambda {@complete_robot.process_item(mock_workitem)}.should raise_exception("Failed to update provenance to include Deposit completion.")
    end
    
    # This test looks at the "sdr_prov" instance var
    # and make sure it contains the XML string for the SDR provenance stanza.
    # It should contain all events bearing "completed" status in sdrIngestWorkflow.
    # It should look like:
    # <agent name="SDR">
    #   <what object="druid:jc837rq9922"
    #     <event who="register-sdr" when="">register-sdr</event>
    #     <event who="transfer-object" when="">transfer-object</event>
    #     ... up to verify-agreement because complete-deposit status would not be marked completed until after this robot runs
    #   </what>
    # </agent>
    it "should compose SDR provenance" do
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      @complete_robot.process_item(mock_workitem)  
      
      @complete_robot.sdr_prov.should_not be_nil
      @complete_robot.sdr_prov.should_not be_empty
      @complete_robot.sdr_prov.should =~ /agent name="SDR"/
      @complete_robot.sdr_prov.should =~ /what object="#{objectID}"/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:register-sdr" when=/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:transfer-object" when=/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:validate-bag" when=/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:populate-metadata" when=/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:verify-agreement" when=/
    end
        
    # Existing provenance might look like this:
    # <agent name="Google"> ... </agent>
    # <agent name="DOR"> ... </agent>
    # After appending SDR provenance, we should see an additional
    # <agent name="SDR"> ... </agent>  
    it "should make SDR provenance part of the object's provenance" do
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      @complete_robot.process_item(mock_workitem)  

      @complete_robot.obj_prov.should_not be_nil
      @complete_robot.obj_prov.should_not be_empty
      # @complete_robot.obj_prov.should =~ /agent name="Google"/
      # @complete_robot.obj_prov.should =~ /agent name="DOR"/
      
      @complete_robot.obj_prov.should =~ /agent name="SDR"/      
      @complete_robot.sdr_prov.should =~ /what object="#{objectID}"/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:register-sdr" when=/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:transfer-object" when=/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:validate-bag" when=/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:populate-metadata" when=/
      @complete_robot.sdr_prov.should =~ /event who="SDR-robot:verify-agreement" when=/
    end
    
    # This test reads the provenance back from the Sedora object,
    # and verifies that the SDR provenance actually got written to the Sedora obj.
    # The test strings in this test look different from those from above. 
    # Namely this test's strings don't include "event" and "when=".
    # When datastream content is read back from Sedora, the attributes are not always in the same order they were written.
    # So what gets read back looks like <event when="" who="SDR-robot: register-sdr"> register-sdr</event>.
    # It's still valid, but the test can't test that the when and who attrs are in the same order they got written.
    it "updates Sedora Provenance Datastream with the SDR provenance added" do
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      @complete_robot.process_item(mock_workitem)  
      
      prov_ds = @complete_robot.obj.datastreams['PROVENANCE']
      prov_read_back = prov_ds.content
      
      prov_read_back.should_not be_nil
      prov_read_back.should_not be_empty
      prov_read_back.should =~ /agent name="SDR"/      
      prov_read_back.should =~ /what object="#{objectID}"/
      prov_read_back.should =~ /event/
      prov_read_back.should =~ /who="SDR-robot:register-sdr"/
      prov_read_back.should =~ /who="SDR-robot:transfer-object"/
      prov_read_back.should =~ /who="SDR-robot:validate-bag"/
      prov_read_back.should =~ /who="SDR-robot:populate-metadata"/
      prov_read_back.should =~ /who="SDR-robot:verify-agreement"/
      
    end      
  end
  
  context "Update DOR workflow" do
    before(:each) do
      setup
    end
    
    after(:each) do
      cleanup
    end
        
    it "should update DOR workflow to sdr-deposit-complete" do
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")

      # verify that Dor::WorkflowService.update_workflow_status is called      
      Dor::WorkflowService.stub(:update_workflow_status).and_return(true)
      Dor::WorkflowService.should_receive(:update_workflow_status).with("dor", "druid:jc837rq9922", "googleScannedBookWF", "sdr-ingest-complete", "completed")
      
      # actually call the function we are testing
      @complete_robot.process_item(mock_workitem)
    end
    
    it "should report an error if workflow update failed" do
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
      
      Dor::WorkflowService.stub(:update_workflow_status).and_raise("Update workflow \"complete-deposit\" failed")
      Dor::WorkflowService.should_receive(:update_workflow_status).with("dor", "druid:jc837rq9922", "googleScannedBookWF", "sdr-ingest-complete", "completed")
      
      lambda {@complete_robot.process_item(mock_workitem)}.should raise_error("Update workflow \"complete-deposit\" failed")
    end
  end
end
