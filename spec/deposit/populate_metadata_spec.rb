require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'deposit/populate_metadata'

describe Deposit::PopulateMetadata do

  context "processing a workitem" do
    before(:all) do
      # in the test environment, and only when we want to test against the SDR2_EXAMPLE_OBJECTS,
      # have these tests assume that the SDR2_EXAMPLE_OBJECTS dir is the SDR_DEPOSIT_DIR
      @robot = Deposit::PopulateMetadata.new("deposit","populate-metadata")
      @mock_workitem = mock("workitem")
    
      # return druid:123 when work_item.druid is called
      @mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
    end
    
    it "should be able to access a fedora object" do
      @robot.should respond_to(:obj)
    end
    
    it "should be able to access a bag object" do
      @robot.should respond_to(:bag)
    end
    
    # it "should accept a workitem" do
    #   @robot.should respond_to("process_item(#{@mock_workitem})")
    # end
    #   

    #   
    # it "should load a sedora object with the given druid" do
    #   @robot.obj.should be_instance_of(ActiveFedora::Base)
    #   @robot.obj.pid.should eql(@mock_workitem.druid)
    # end
    #   
    # it "should throw an error if it can't find a sedora object with the given druid" do
    #   pending("If we query sedora with a druid and don't get anything back, what's our fail behavior?")
    # end
  
    # it "should be able to find a bag corresponding to the workitem's druid" do
    #   @robot.bag.should eql(File.expand_path(SDR2_EXAMPLE_OBJECTS + '/jc837rq9922'))
    #   # (File.directory? @robot.bag).should eql(true)
    # end
    # 
    # it "should throw an error if it can't find the bag object" do
    #   pending("")
    # end
    # 
    # it "should be able to extract the identity metadata from the bag" do
    #   
    # end
    
  end

 #  it "should transfer an object" do
 # 
 # # create new transferObject
 #     transfer_robot = Deposit::TransferObject.new( "deposit", "transfer-object")
 # # mock out a workitem
 #     mock_workitem = mock("workitem")
 # # return druid:123 when work_item.druid is called
 #     mock_workitem.stub!(:druid).and_return("druid:123")
 # # verify that FileUtilies.transfer_obejct is called
 #     FileUtilities.should_receive(:transfer_object)
 # 
 # # actually call the function we are testing
 #     transfer_robot.process_item(mock_workitem)
 # 
 #   end

end