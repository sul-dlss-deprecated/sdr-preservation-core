require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'lyber_core/utils'
require 'sdrIngest/transfer_object'

describe SdrIngest::TransferObject do


  context "transfer" do
    
    it "should create the unpack command correct" do
      pending "We should split the creation of the unpack command into a separate method so we can test it"
    end
    
    it "should be able to tell us what directory it's creating" do
      pending "Once we have a create_unpack_command method, we can stub the tar command"
      # transfer_robot.should_receive("create_unpack_command").and_return("foo")
      # transfer_robot.should_receive("system").with("foo").and_return(true)
      
      # create new transferObject
      transfer_robot = SdrIngest::TransferObject.new()
      # mock out a workitem
      mock_workitem = mock("workitem")
      # return druid:ab123cd4567 when work_item.druid is called
      mock_workitem.stub!(:druid).and_return("druid:ab123cd4567")
      LyberCore::Utils::FileUtilities.stub!(:transfer_object).and_return(true)
      transfer_robot.should_receive("system").with("")
      transfer_robot.process_item(mock_workitem).should == true
      druid="druid:ab123cd4567"
      transfer_robot.dest_path.should == SdrDeposit.local_bag_path(druid)
    end
      
    it "should return true if it is a successful transfer" do
      pending
      druid = 'druid:ab123cd4567'
      # create new transferObject
      transfer_robot = SdrIngest::TransferObject.new()
      # mock out a workitem
      mock_workitem = mock("workitem")
      # return druid:ab123cd4567 when work_item.druid is called
      mock_workitem.stub!(:druid).and_return(druid)
      
      File.stub!(:exists?).and_return(false)
      LyberCore::Utils::FileUtilities.stub!(:transfer_object).and_return(true)
      
      # verify that FileUtilies.transfer_obejct is called
      LyberCore::Utils::FileUtilities.should_receive(:transfer_object).with("#{druid}.tar", DOR_WORKSPACE_DIR, SdrDeposit.local_bag_parent_dir(druid)).once

      # actually call the function we are testing
      transfer_robot.process_item(mock_workitem).should == true
    end
      
    it "should raise an error if transfer fails" do
      druid = 'druid:ab123cd4567'
      # create new transferObject
      transfer_robot = SdrIngest::TransferObject.new()
      # mock out a workitem
      mock_workitem = mock("workitem")
      # return druid:ab123cd4567 when work_item.druid is called
      mock_workitem.stub!(:druid).and_return(druid)
      
      File.stub!(:exists?).and_return(false)
      LyberCore::Utils::FileUtilities.stub!(:transfer_object).and_raise("rsync failed")
      
      # verify that FileUtilies.transfer_obejct is called
      LyberCore::Utils::FileUtilities.should_receive(:transfer_object).with("#{druid}.tar", DOR_WORKSPACE_DIR, SdrDeposit.local_bag_parent_dir(druid)).once

      # actually call the function we are testing
      lambda {transfer_robot.process_item(mock_workitem)}.should raise_error
    end
    
    it "should not transfer a pre-existing object of the same druid" do
      # create new transferObject
      transfer_robot = SdrIngest::TransferObject.new()
      # mock out a workitem
      mock_workitem = mock("workitem")

      objId = "druid:ab123cd4567"
      # return druid:ab123cd4567 when work_item.druid is called
      mock_workitem.stub!(:druid).and_return(objId)
      
      File.stub!(:exists?).and_return(true)

      # verify that FileUtilies.transfer_obejct is never called
      LyberCore::Utils::FileUtilities.should_receive(:transfer_object).never

      # actually call the function we are testing
      lambda {transfer_robot.process_item(mock_workitem)}.should_not raise_error(/Object already exists/)
      
    end
        
  end
end
