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
  
  context "Update workflow" do
    before(:each) do
      setup
    end
    
    after(:each) do
      cleanup
    end
    
    it "should be able to process a work item" do
      @complete_robot.should respond_to(:process_item)
    end
    
    it "should update Sedora workflow to DepositComplete" do
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")

      # verify that Dor::WorkflowService.update_workflow_status is called      
      Dor::WorkflowService.stub(:update_workflow_status).and_return(true)
      Dor::WorkflowService.should_receive(:update_workflow_status).with("sdr", "druid:jc837rq9922", "sdrIngestWF", "complete-deposit", "completed")
      
      # actually call the function we are testing
      @complete_robot.process_item(mock_workitem).should == true
    end
    
    it "should report an error if workflow update failed" do
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
      
      Dor::WorkflowService.stub(:update_workflow_status).and_raise("Update workflow \"complete-deposit\" failed")
      Dor::WorkflowService.should_receive(:update_workflow_status).with("sdr", "druid:jc837rq9922", "sdrIngestWF", "complete-deposit", "completed")
      
      lambda {@complete_robot.process_item(mock_workitem)}.should raise_error("Update workflow \"complete-deposit\" failed")
    end
  end
  
  context "can load Sedora object with corresponding druid" do
    before(:each) do
      setup
    end
    
    after(:each) do
      cleanup
    end
    
    it "should be able to access a Sedora object" do
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
    
    it "should update provenance to DepositComplete" do 
      pending
      
      objectID = "druid:jc837rq9922"
      mock_workitem = mock("complete_deposit_workitem")
      mock_workitem.stub!(:druid).and_return(objectID)

      #@complete_robot.process_item(mock_workitem)
            
      @complete_robot.stub!(:update_provenance).and_return(true)
      @complete_robot.should_receive(:update_provenance).with("deposit complete")
      
      # Load the Sedora object and update its provenance datastream
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)
      

    end
    
    it "should report an error if update provenance failed" do
      pending
    end
  end
  
  context "Notify DOR" do
    it "should notify DOR of deposit complete" do
      pending()
    end
  
    it "should report an error if notifying DOR failed" do
      pending
    end
    
  end
end
