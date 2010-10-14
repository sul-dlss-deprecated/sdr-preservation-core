require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'lyber_core/utils'
require 'sdrIngest/transfer_object'

describe SdrIngest::TransferObject do


  context "transfer" do
    
    it "should be able to tell us what directory it's creating" do
      # create new transferObject
      transfer_robot = SdrIngest::TransferObject.new( "sdrIngestWF", "transfer-object")
      # mock out a workitem
      mock_workitem = mock("workitem")
      # return druid:123 when work_item.druid is called
      mock_workitem.stub!(:druid).and_return("druid:123")
      LyberCore::Utils::FileUtilities.stub!(:transfer_object).and_return(true)
      transfer_robot.process_item(mock_workitem).should == true
      transfer_robot.dest_path.should == File.join(SDR_DEPOSIT_DIR,"druid:123")
    end
      
    it "should return true if it is a successful transfer" do
      # create new transferObject
      transfer_robot = SdrIngest::TransferObject.new( "sdrIngestWF", "transfer-object")
      # mock out a workitem
      mock_workitem = mock("workitem")
      # return druid:123 when work_item.druid is called
      mock_workitem.stub!(:druid).and_return("druid:123")
      
      File.stub!(:exists?).and_return(false)
      LyberCore::Utils::FileUtilities.stub!(:transfer_object).and_return(true)
      
      # verify that FileUtilies.transfer_obejct is called
      LyberCore::Utils::FileUtilities.should_receive(:transfer_object).with("druid:123.tar", DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR).once

      # actually call the function we are testing
      transfer_robot.process_item(mock_workitem).should == true
    end
      
    it "should raise and error if transfer fails" do
      # create new transferObject
      transfer_robot = SdrIngest::TransferObject.new( "sdrIngestWF", "transfer-object")
      # mock out a workitem
      mock_workitem = mock("workitem")
      # return druid:123 when work_item.druid is called
      mock_workitem.stub!(:druid).and_return("druid:123")
      
      File.stub!(:exists?).and_return(false)
      LyberCore::Utils::FileUtilities.stub!(:transfer_object).and_raise("rsync failed")
      
      # verify that FileUtilies.transfer_obejct is called
      LyberCore::Utils::FileUtilities.should_receive(:transfer_object).with("druid:123.tar", DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR).once

      # actually call the function we are testing
      lambda {transfer_robot.process_item(mock_workitem)}.should raise_error
    end
    
    it "should not transfer a pre-existing object of the same druid" do
      # create new transferObject
      transfer_robot = SdrIngest::TransferObject.new( "sdrIngestWF", "transfer-object")
      # mock out a workitem
      mock_workitem = mock("workitem")

      objId = "druid:123"
      # return druid:123 when work_item.druid is called
      mock_workitem.stub!(:druid).and_return(objId)
      
      File.stub!(:exists?).and_return(true)

      # verify that FileUtilies.transfer_obejct is never called
      LyberCore::Utils::FileUtilities.should_receive(:transfer_object).never

      # actually call the function we are testing
      lambda {transfer_robot.process_item(mock_workitem)}.should_not raise_error(/Object already exists/)
      
    end
        
  end
end
