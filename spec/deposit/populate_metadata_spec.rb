require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'deposit/populate_metadata'

describe Deposit::PopulateMetadata do

  context "processing a workitem" do
  before(:all) do
    # in the test environment, and only when we want to test against the SDR2_EXAMPLE_OBJECTS,
    # have these tests assume that the SDR2_EXAMPLE_OBJECTS dir is the SDR_DEPOSIT_DIR
    SDR_DEPOSIT_DIR = SDR2_EXAMPLE_OBJECTS
    @robot = Deposit::PopulateMetadata.new("deposit","populate-metadata")
    @mock_workitem = mock("workitem")
    
    # return druid:123 when work_item.druid is called
    @mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
  end
    
    it "should accept a workitem" do
      @robot.process_item(@mock_workitem)
    end
    
    it "should be able to access a fedora object" do
      @robot.should respond_to("obj")
    end
    
    it "should load a sedora object with the given druid" do
      @robot.obj.should be_instance_of(ActiveFedora::Base)
      @robot.obj.pid.should eql(@mock_workitem.druid)
    end
    
    it "should throw an error if it can't find a sedora object with the given druid" do
      pending("If we query sedora with a druid and don't get anything back, what's our fail behavior?")
    end
  
    it "should be able to find a bag corresponding to the workitem's druid" do
      bagit_filename = SDR_DEPOSIT_DIR + '/' + @mock_workitem.druid.split(":")[1]
      bagit_filename.should eql("/usr/local/projects/sdr2/config/environments/../../sdr2_example_objects/jc837rq9922")
      (File.directory? bagit_filename).should eql(true)
    end
    
    
    
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