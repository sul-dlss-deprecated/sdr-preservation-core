require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdrIngest/complete_deposit'


describe SdrIngest::CompleteDeposit do
  
  context "Update workflow" do
    before(:each) do
      @objectID = "druid:123"
      
      @complete_robot = SdrIngest::CompleteDeposit.new("sdrIngest", "complete-deposit")
      @mock_workitem = mock('workitem')
      @mock_workitem.stub!(:druid).and_return(@objectID)      
    end
    
    it "should update Sedora workflow to DepositComplete" do
      
      # verify that Dor::WorkflowService.update_workflow_status is called      
      Dor::WorkflowService.stub(:update_workflow_status).and_return(true)
      Dor::WorkflowService.should_receive(:update_workflow_status).with("sdr", @objectID, "sdrIngestWF", "complete-deposit", "completed")
      
      # actually call the function we are testing
      @complete_robot.process_item(@mock_workitem).should == true
    end
    
    it "should report an error if workflow update failed" do
      Dor::WorkflowService.stub(:update_workflow_status).and_raise("Update workflow \"complete-deposit\" failed")
      Dor::WorkflowService.should_receive(:update_workflow_status).with("sdr", @objectID, "sdrIngestWF", "complete-deposit", "completed")
      
      lambda {@complete_robot.process_item(@mock_workitem)}.should raise_error("Update workflow \"complete-deposit\" failed")
    end
  end
  
  context "Update provenance" do

    
    it "should update provenance to DepositComplete" do
      pending
      @complete_robot.stub!(:update_provenance).and_return(true)
      @complete_robot.should_receive(:update_provenance).with(@objectID, "deposit complete")
      @complete_robot.process_item(@mock_workitem).should == true
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
