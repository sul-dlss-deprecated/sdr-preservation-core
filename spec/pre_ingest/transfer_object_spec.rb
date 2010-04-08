require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'google_scanned_book/descriptive_metadata'
require 'lyber_core'

describe PreIngest::TransferObject do

  it "should transfer an object" do
    transfer_robot = PreIngest::TransferObject.new( "DepositWorkflow", "transfer_object")
    mock_workitem = mock("workitem")
    mock_workitem.stub!(:druid).and_return("druid:123")
    FileUtilities.should_receive(:transfer_object)
    transfer_robot.process_item(mock_workitem)


  end

end