require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../robots/sdrIngest/provenance_metadata')

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
  
  context "create sdr provenance" do
    before(:each) do
      setup
    end
    
    after(:each) do
      cleanup
    end
    
    it "should respond to create_sdr_provenance method" do
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")

      @complete_robot.should_receive(:create)
      @complete_robot.process_item(mock_workitem)
    end

    it "should create valid SDR provenance" do
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")

      @complete_robot.should_receive(:create)


      @complete_robot.process_item(mock_workitem)
#    @complete_robot.sdr_provXML = "foo"
      @complete_robot.sdr_provXML.should_not be_nil      

    end

  end
  
  context "Update provenance" do
    before(:each) do
      setup
    end
    
    after(:each) do
      cleanup
    end

    it "should respond to update_provenance" do
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      @complete_robt.stub!(:update_provenance).and_return(true)
      @complete_robot.should_receive(:update_provenance).and_return(true)
      @complete_robot.process_item(mock_workitem)
    end

    it "should raise error if update provenance fails" do
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      @complete_robot.stub!(:update_provenance).and_return(false)
      lambda {@complete_robot.process_item(mock_workitem)}.should raise_exception("Failed to update provenance to include Deposit completion.")
    end
    
    it "should respond positively to create_sdr_provenance" do
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)
      
      @complete_robot.should_receive(:create_sdr_provenance)
      @complete_robot.process_item(mock_workitem)
    end
    
    # Test to make sure create_sdr_provenance is creating valid SDR prov md 
    it "should create valid new SDR provenance metadata" do 
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      @complete_robot.should_receive(:create_sdr_provenance)
      @complete_robot.process_item(mock_workitem)

      @complete_robot.sdr_provXML.should_not be_nil
      @complete_robot.sdr_provXML.should_not be_empty
      @complete_robot.sdr_provXML.should be_instance_of(String)
      
      # xmlDoc = Nokogiri::XML(@complete_robot.sdr_provXML)
      #       xmlDoc.xpath("/agent").should_not be_nil
    end
    
    # This and the next test would not necessarily be true if SDR keeps its own prov datastream
    it "should have a provenance datastream" do
      pending
      
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      # Load the Sedora object and retrieve its provenance datastream
      ds = {"CONTENT" => "content", "PROVENANCE" => "provenance"}
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)
      @complete_robot.stub!(:obj).and_return(obj)
      
      obj.stub!(:datastreams).and_return(ds)
      obj.should_receive(:datastreams).and_return({"PROVENANCE"=>"provenance"})
      @complete_robot.process_item(mock_workitem)
    end
    
    it "should raise an error if the obj doesn't have a provenance md datastream" do
      pending
      
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)
      
      ds = {"CONTENT" => "content"}
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)
      @complete_robot.stub!(:obj).and_return(obj)
      
      # The object has no PROVENANCE md ds
      obj.stub!(:datastreams).and_return(ds)
      obj.should_receive(:datastreams).and_return({"PROVENANCE"=>nil})
      
      lambda {@complete_robot.process_item(mock_workitem)}.should raise_exception("Provenance metadata datastream not found.")
    end
    
    # how to test Nokogiri::XML(xml)???
    it "should verify the existing provenance datastream contains valid XML" do
      pending
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)
      
      ex_prov_xml = %{<?xml version="1.0"?>
      <provenanceMetadata objectId="druid:jc837rq9922">
          <agent name="DOR">
          </agent>
        </provenanceMetadata>
      }
      
            event = Event.new
            event.event = "SDR event"
            event.who="SDR-robot"
            event.when = "whenever"

            what = What.new
            what.object = @druid
      #      what.event = events 
            what.event = [event]

            agent = Agent.new
            agent.name = "SDR"
            agent.what = what
            
      @complete_robot.stub!(:create_sdr_provenance).and_return(agent)
      @complete_robot.stub!(:retrieve_existing_provenance).and_return(ex_prov_xml)

      @complete_robot.should_receive(:append_provenance).with(ex_prov_xml, agent)
#      Nokogiri::XML.should_receive(:parse).with(ex_prov_xml)

      @complete_robot.process_item(mock_workitem)
    end
     
    it "should append SDR provenance to existing provenance if there is any" do
      pending
      
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)
      
      ex_prov_xml = %{<?xml version="1.0"?>
      <provenanceMetadata objectId="druid:jc837rq9922">
          <agent name="DOR">
          </agent>
        </provenanceMetadata>
      }
      ex_prov = Nokogiri::XML(ex_prov_xml)
      
      sdr_prov_xml = %{   <agent name="SDR">
          </agent>}
      sdr_prov = Nokogiri::XML(sdr_prov_xml)
      
      @complete_robot.process_item(mock_workitem)
  
    end
    
    it "should delete existing provenance metadata datastream" do
      pending
        # Append SDR md to existing provenance md datastream
        @complete_robot.stub!(:update_provenance).and_return(true)
        @complete_robot.should_receive(:update_provenance).with("deposit complete")
        SdrService.should_receive(:update_datastream).with(objectID, "PROVENANCE")
    
    end
    
    it "should raise error if deleting existing prov ds failed" do
      pending
    end
    
    it "should add new prov md ds" do
      pending
      
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)
 
      @complete_robot.stub!(:create_sdr_provenance)
      @complete_robot.stub!(:retrieve_existing_provenance).and_return("xml_str")
      @complete_robot.stub!(:append_provenance)
      
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)

      # The call looks like this:     self.obj.add_datastream(:pid=>@druid, :dsid=>ds_id, :dsLabel=>ds_label, :content=>provXML.to_s) 
      # How to test the parameters?
      obj.should_receive(:add_datastream)
      @complete_robot.process_item(mock_workitem)
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
