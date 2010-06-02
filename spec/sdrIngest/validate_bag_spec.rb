require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdrIngest/validate_bag'

describe SdrIngest::ValidateBag do

  context "validate" do
    
      it "should return nil when bag is valid" do
        robot = SdrIngest::ValidateBag.new("sdrIngest", "validate-bag")
        mock_workitem = mock("workitem")
        mock_workitem.stub!(:druid).and_return("druid:123")
        mock_bag = mock("bag")
        BagIt::Bag.stub!(:new).and_return(mock_bag)
        mock_bag.stub!(:valid?).and_return(true)
        
        robot.process_item(mock_workitem).should be_nil
      end

      it "should raise error when bag is not valid" do
        robot = SdrIngest::ValidateBag.new("sdrIngest", "validate-bag")
        mock_workitem = mock("workitem")
        mock_workitem.stub!(:druid).and_return("druid:123")
        mock_bag = mock("bag")
        BagIt::Bag.stub!(:new).and_return(mock_bag)
        mock_bag.stub!(:valid?).and_return(false)
        
        lambda {robot.process_item(mock_workitem)}.should raise_error
      end
  end
end