require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdrIngest/validate_bag'

describe SdrIngest::ValidateBag do 
  
  context "bag_exists?" do
      it "should return false when base_path does not exist" do
        base_path = File.join(Dir.tmpdir, "lkdjflksdjda")
      	puts base_path
      	FileUtils.rm_rf(base_path)

        robot = SdrIngest::ValidateBag.new("sdrIngest", "validate-bag")
      	robot.bag_exists?(base_path).should == false
      end

      it "should return false when base_path is not a directory" do 
        pending("writing the test case")
      end

      it "should return false when data_dir does not exist" do
        pending("writing the test case")
      end

      it "should return false when data_dir is not a directory" do
        pending("writing the test case")
      end

      it "should return false when bagit_txt_file does not exist" do
        pending("writing the test case")
      end

      it "should return false when bagit_txt_file is not a file" do
        pending("writing the test case")
      end

      it "should return false when package_info_txt_file does not exist" do
        pending("writing the test case")
      end

      it "should return false when package_info_txt_file is not a file" do
        pending("writing the test case")
      end

      it "should return true when it is a real bag" do
        base_path = File.join(Dir.tmpdir, "lkdjflksdjfalda")
        BagIt::Bag.new(base_path)

        robot = SdrIngest::ValidateBag.new("sdrIngest", "validate-bag")
	robot.bag_exists?(base_path).should == true

	FileUtils.rm_rf(base_path)
      end
  end

  context "validate" do
    
      it "should raise error when bag does not exist" do
        robot = SdrIngest::ValidateBag.new("sdrIngest", "validate-bag")
        mock_workitem = mock("workitem")
        mock_workitem.stub!(:druid).and_return("druid:123")

        lambda {robot.process_item(mock_workitem)}.should raise_error
      end

      it "should return nil when bag is valid" do
        robot = SdrIngest::ValidateBag.new("sdrIngest", "validate-bag")
        mock_workitem = mock("workitem")
        mock_workitem.stub!(:druid).and_return("druid:123")
        mock_bag = mock("bag")
	robot.stub!(:bag_exists?).and_return(true)
        BagIt::Bag.stub!(:new).and_return(mock_bag)
        mock_bag.stub!(:valid?).and_return(true)
        
        robot.process_item(mock_workitem).should be_nil
      end

      it "should raise error when bag is not valid" do
        robot = SdrIngest::ValidateBag.new("sdrIngest", "validate-bag")
        mock_workitem = mock("workitem")
        mock_workitem.stub!(:druid).and_return("druid:123")
        mock_bag = mock("bag")
	robot.stub!(:bag_exists?).and_return(true)
        BagIt::Bag.stub!(:new).and_return(mock_bag)
        mock_bag.stub!(:valid?).and_return(false)
        
        lambda {robot.process_item(mock_workitem)}.should raise_error
      end
  end
end