require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'rubygems'
require 'lyber_core'
require 'sdrIngest/complete_deposit'


describe SdrIngest::CompleteDeposit do
  
  def setup
    @complete_robot = SdrIngest::CompleteDeposit.new()    
    @complete_robot.bag_directory = SDR2_EXAMPLE_OBJECTS

    @objectID = "druid:jc837rq9922"
    
    @mock_workitem = mock("complete_deposit_workitem")
    @mock_workitem.stub!(:druid).and_return(@objectID)    
    
    Fedora::Repository.register(SEDORA_URI)
    ActiveFedora::SolrService.register(SOLR_URL)
    
    # Make sure we're starting with a blank object
    begin
      @obj = ActiveFedora::Base.load_instance(@mock_workitem.druid)
      @obj.delete unless obj.nil?
    rescue
      # $stderr.print $!
    end
    
    begin
      @obj = ActiveFedora::Base.new(:pid => @mock_workitem.druid)
      @obj.save
    
      @obj = ActiveFedora::Base.load_instance(@mock_workitem.druid)
      @mock_workitem.stub!(:obj).and_return(@obj)
        
      wf_str = %{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workflow objectId="druid:jc837rq9922" id="sdrIngestWF">
        <process lifecycle="inprocess" elapsed="0.0" attempts="0" datetime="2010-06-08T22:09:43-0700" status="completed" name="register-sdr"/>
        <process elapsed="0.158" attempts="1" datetime="2010-06-08T22:14:07-0700" status="completed" name="transfer-object"/>
        <process elapsed="0.104" attempts="1" datetime="2010-06-08T22:16:27-0700" status="completed" name="validate-bag"/>
        <process elapsed="0.481" attempts="1" datetime="2010-06-08T22:19:36-0700" status="completed" name="populate-metadata"/>
        <process elapsed="0.0" attempts="2" datetime="2010-06-21T15:43:33-0700" status="completed" name="verify-agreement"/>
        <process lifecycle="registered" elapsed="0.0" attempts="1" datetime="2010-06-21T15:45:10-0700" status="waiting" name="complete-deposit"/>
        </workflow>}
    
      wf_ds = ActiveFedora::Datastream.new(:pid=>@obj.pid, :dsid=>'sdrIngestWF', :dsLabel=>'sdrIngestWF', :blob=>wf_str)
      @obj.add_datastream(wf_ds)
        
      prov_str = %{<agent name="DOR">
          <what object="druid:bp119bq5041">
            <event when="2010-04-06T10:26:52-0700" who="DOR-robot:register-object">Google data received</event>
            <event when="2010-04-23T15:28:41-0700" who="DOR-robot:google-download">Checksums verified</event>
            <event when="2010-04-23T15:30:13-0700" who="DOR-robot: process-content">Image files JHOVE 1.4 validated</event>
          </what>
        </agent>
      }
      prov_ds = ActiveFedora::Datastream.new(:pid=>@obj.pid, :dsid=>'PROVENANCE', :dsLabel=>'PROVENANCE', :blob=>prov_str)  
      @obj.add_datastream(prov_ds)
      @obj.save
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
      obj.delete unless obj.nil?
    rescue
      # $stderr.print $!
    end

  end
  
  context "basic behavior" do
    it "should be able to process a work item" do
      complete_robot = SdrIngest::CompleteDeposit.new()          
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
      @complete_robot.process_item(@mock_workitem)
      
      @complete_robot.obj.should be_instance_of(ActiveFedora::Base)
      @complete_robot.obj.pid.should eql(@mock_workitem.druid) 
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
      @complete_robot.stub!(:update_provenance).and_return(false)
      lambda {@complete_robot.process_item(@mock_workitem)}.should raise_exception("Failed to update provenance to include Deposit completion.")
    end
    
    # This test looks at the "sdr_prov" instance var
    # and make sure it contains the XML string for the SDR provenance stanza.
    # It should contain all events stored in "sdr_wf",
    # composed by the "retrieve SDR workflow information from the object" step.
    # It should look like:
    # <agent name="SDR">
    #   <what object="druid:jc837rq9922"
    #     <event who="register-sdr" when="">register-sdr</event>
    #     <event who="transfer-object" when="">transfer-object</event>
    #     ... up to verify-agreement because complete-deposit status would not be marked completed until after this robot runs
    #   </what>
    # </agent>
    it "should compose SDR provenance" do

      @complete_robot.process_item(@mock_workitem)  
      
      @complete_robot.sdr_prov.should_not be_nil
      @complete_robot.sdr_prov.should_not be_empty
      @complete_robot.sdr_prov.should =~ /agent name="SDR"/
      @complete_robot.sdr_prov.should =~ /what object="#{@objectID}"/
            
      @complete_robot.sdr_prov.should =~ /event/
      @complete_robot.sdr_prov.should =~ /who="SDR-robot:transfer-object"/
      @complete_robot.sdr_prov.should =~ /who="SDR-robot:validate-bag"/
      @complete_robot.sdr_prov.should =~ /who="SDR-robot:populate-metadata"/
      @complete_robot.sdr_prov.should =~ /who="SDR-robot:verify-agreement"/
      
      # Make sure complete-deposit is NOT included as it is still in "waiting" status.
      @complete_robot.sdr_prov.should_not =~ /who="SDR-robot:complete-deposit"/
    end
        
    # Existing provenance might look like this:
    # <agent name="Google"> ... </agent>
    # <agent name="DOR"> ... </agent>
    # After appending SDR provenance, we should see an additional
    # <agent name="SDR"> ... </agent>  
    it "should make SDR provenance part of the object's provenance" do
      
      @complete_robot.process_item(@mock_workitem)  

      @complete_robot.obj_prov.should_not be_nil
      @complete_robot.obj_prov.should_not be_empty
      
      @complete_robot.obj_prov.should =~ /agent name="SDR"/      
      @complete_robot.obj_prov.should =~ /what object="#{@objectID}"/
      
      @complete_robot.obj_prov.should =~ /event/
      @complete_robot.obj_prov.should =~ /who="SDR-robot:transfer-object"/
      @complete_robot.obj_prov.should =~ /who="SDR-robot:validate-bag"/
      @complete_robot.obj_prov.should =~ /who="SDR-robot:populate-metadata"/
      @complete_robot.obj_prov.should =~ /who="SDR-robot:verify-agreement"/
      
      # Make sure complete-deposit is NOT included as it is still in "waiting" status.
      @complete_robot.obj_prov.should_not =~ /who="SDR-robot:complete-deposit"/
    end
    
    # This test reads the provenance back from the Sedora object,
    # and verifies that the SDR provenance actually got written to the Sedora obj.
    # The test strings in this test look different from those from above. 
    # Namely this test's strings don't include "event" and "when=".
    # When datastream content is read back from Sedora, the attributes are not always in the same order they were written.
    # So what gets read back looks like <event when="" who="SDR-robot: register-sdr"> register-sdr</event>.
    # It's still valid, but the test can't test that the when and who attrs are in the same order they got written.
    it "updates Sedora Provenance Datastream with the SDR provenance added" do
      @complete_robot.process_item(@mock_workitem)  
      
      prov_ds = @complete_robot.obj.datastreams['PROVENANCE']
      prov_read_back = prov_ds.content
      
      prov_read_back.should_not be_nil
      prov_read_back.should_not be_empty
      prov_read_back.should =~ /agent name="SDR"/      
      prov_read_back.should =~ /what object="#{@objectID}"/
      prov_read_back.should =~ /event/
      prov_read_back.should =~ /who="SDR-robot:register-sdr"/
      prov_read_back.should =~ /who="SDR-robot:transfer-object"/
      prov_read_back.should =~ /who="SDR-robot:validate-bag"/
      prov_read_back.should =~ /who="SDR-robot:populate-metadata"/
      prov_read_back.should =~ /who="SDR-robot:verify-agreement"/
      prov_read_back.should_not =~ /who="SDR-robot:complete-deposit"/
    end      
  end
  
  context "Update DOR workflow" do
    before(:each) do
      setup
    end
    
    after(:each) do
      cleanup
    end
        
    # How do we test this?  We need to call the method and then read the googleScannedBook workflow to verify the status...    
    it "should update DOR workflow to sdr-deposit-complete" do
      pending
      # actually call the function we are testing
      @complete_robot.process_item(@mock_workitem)
    end
    
    it "should report an error if workflow update failed" do
      Dor::WorkflowService.should_receive(:update_workflow_status).with("dor", "druid:jc837rq9922", "googleScannedBookWF", "sdr-ingest-deposit", "completed")
      
      lambda {@complete_robot.process_item(@mock_workitem)}.should raise_error(/Update workflow "complete-deposit" failed/)
    end
  end



end
