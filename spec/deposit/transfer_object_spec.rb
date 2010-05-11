require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'deposit/transfer_object'

describe Deposit::TransferObject do


  context "successful transfers" do
    context "local transfers" do 
      before(:all) do
        dir = Dir.pwd
        DOR_WORKSPACE_DIR="#{dir}/sdr2_example_objects/"
        SDR_DEPOSIT_DIR="#{dir}/tmp/"
        FileUtils.mkdir(SDR_DEPOSIT_DIR)
        
      end
    
      after(:all) do
        FileUtils.remove_dir(SDR_DEPOSIT_DIR, true)
      end
      
      it "should transfer an object locally" do

        # create new transferObject
        transfer_robot = Deposit::TransferObject.new( "deposit", "transfer-object")
        # mock out a workitem
        mock_workitem = mock("workitem")
        # return druid:123 when work_item.druid is called
        mock_workitem.stub!(:druid).and_return("druid:123")
        # verify that FileUtilies.transfer_obejct is called
        FileUtilities.should_receive(:transfer_object).with("druid:123", DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR).once

        # actually call the function we are testing
        transfer_robot.process_item(mock_workitem)
      end
      
      # it "should find the transferred object in the local destination" do
      #     
      #   # create new transferObject
      #   transfer_robot = Deposit::TransferObject.new( "deposit", "transfer-object")
      #   # mock out a workitem
      #   mock_workitem = mock("workitem")
      #   
      #   objId = "jc837rq9922"        
      #   if !File.exist?(DOR_WORKSPACE_DIR + objId) then
      #     raise('You need to get the test obj first.  Do "git submodule init", then "git submodule update".')
      #   end
      #    
      #   # return druid:123 when work_item.druid is called
      #   mock_workitem.stub!(:druid).and_return(objId)
      #   # actually call the function we are testing
      #   transfer_robot.process_item(mock_workitem).should == true
      # end
    end
    
    context "network transfers" do
      before(:all) do
        DOR_WORKSPACE_DIR="localhost:/tmp/dorWorkspaceDir"
        SDR_DEPOSIT_DIR="/tmp/sdrDepositDir"
      end
      
      it "should transfer an object across network" do
           pending()
           # create new transferObject
           transfer_robot = Deposit::TransferObject.new( "deposit", "transfer-object")
           # mock out a workitem
           mock_workitem = mock("workitem")
           # return druid:123 when work_item.druid is called
           mock_workitem.stub!(:druid).and_return("foo")
           # verify that FileUtilies.transfer_obejct is called
           FileUtilities.should_receive(:transfer_object).with("foo", DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR).once

           # actually call the function we are testing
           transfer_robot.process_item(mock_workitem)
      end

      it "should find the transferred object in the destination across network" do
         pending()
      end

      it "should report error when network transfer failed" do
         pending()
       end
    end

  end 
  
  context "error conditions" do
    it "should report error when source is unreadable" do
      pending()
    end

    it "should report error when destination is unwritable" do
      pending()
    end

    it "should report error when source server doesn't exist" do
      pending()
    end

    it "should report error when destination server doesn't exist" do
      pending()
    end
    
    it "should report when transfer failed" do
      pending()
    end
    
  end
end