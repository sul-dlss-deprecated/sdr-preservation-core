require 'sdr/validate_bag'
require 'spec_helper'

describe Sdr::ValidateBag do

  before(:all) do
    @druid = "druid:jc837rq9922"

  end

  before(:each) do
    @vb = ValidateBag.new
  end

  specify "ValidateBag#initialize" do
    @vb.should be_instance_of ValidateBag
    @vb.should be_kind_of LyberCore::Robots::Robot
    @vb.workflow_name.should == 'sdrIngestWF'
    @vb.workflow_step.should == 'validate-bag'
  end

  specify "ValidateBag#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @vb.should_receive(:validate_bag).with(@druid)
    @vb.process_item(work_item)
  end

  specify "ValidateBag#validate_bag" do
    @vb.should_receive(:validate_bag_structure).with(@druid)
    @vb.should_receive(:validate_bag_data).with(@druid)
    @vb.validate_bag(@druid)
  end

  specify "ValidateBag#validate_bag_structure" do
    bag_dir = mock('bagdir')
    SdrDeposit.stub(:bag_pathname).with(@druid).and_return(bag_dir)
    bag_dir.stub(:to_s).and_return('bagdir')
    bag_dir.stub(:directory?).and_return(false)
    lambda{@vb.validate_bag_structure(@druid)}.should raise_exception(/bagdir does not exist/)
    bag_dir.stub(:directory?).and_return(true)

    data_dir = mock('datadir')
    bag_dir.stub(:join).with('data').and_return(data_dir)
    data_dir.stub(:to_s).and_return('datadir')
    data_dir.stub(:directory?).and_return(false)
    lambda{@vb.validate_bag_structure(@druid)}.should raise_exception(/datadir does not exist/)
    data_dir.stub(:directory?).and_return(true)

    bagit_txt_file = mock('bagit_txt_file')
    bag_dir.stub(:join).with('bagit.txt').and_return(bagit_txt_file)
    bagit_txt_file.stub(:to_s).and_return('bagit_txt_file')
    bagit_txt_file.stub(:file?).and_return(false)
    lambda{@vb.validate_bag_structure(@druid)}.should raise_exception(/bagit_txt_file does not exist/)
    bagit_txt_file.stub(:file?).and_return(true)

    bag_info_txt_file = mock('bag_info_txt_file')
    bag_dir.stub(:join).with('bag-info.txt').and_return(bag_info_txt_file)
    bag_info_txt_file.stub(:to_s).and_return('bag_info_txt_file')
    bag_info_txt_file.stub(:file?).and_return(false)
    lambda{@vb.validate_bag_structure(@druid)}.should raise_exception(/bag_info_txt_file does not exist/)
    bag_info_txt_file.stub(:file?).and_return(true)

    @vb.validate_bag_structure(@druid).should == true
  end

  specify "ValidateBag#validate_bag_data" do
    bag = mock('Bag')
    BagIt::Bag.stub(:new).with(SdrDeposit.bag_pathname(@druid).to_s).and_return(bag)
    bag.should_receive(:valid?).and_return(false)
    lambda{@vb.validate_bag_data(@druid)}.should raise_exception(LyberCore::Exceptions::ItemError)

    bag.should_receive(:valid?).and_return(true)
    @vb.validate_bag_data(@druid).should == true
  end

  
end
