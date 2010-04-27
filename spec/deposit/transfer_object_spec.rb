require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'deposit/transfer_object'

describe Deposit::TransferObject do

  before(:all) do
    DOR_WORKSPACE_DIR="/tmp/dorWorkspaceDir"
    SDR_DEPOSIT_DIR="/tmp/sdrDepositDir"
  end

  it "should transfer an object" do

# create new transferObject
    transfer_robot = Deposit::TransferObject.new( "deposit", "transfer-object")
# mock out a workitem
    mock_workitem = mock("workitem")
# return druid:123 when work_item.druid is called
    mock_workitem.stub!(:druid).and_return("druid:123")
# verify that FileUtilies.transfer_obejct is called
    FileUtilities.should_receive(:transfer_object)

# actually call the function we are testing
    transfer_robot.process_item(mock_workitem)

  end

end