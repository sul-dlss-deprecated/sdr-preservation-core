require 'sdr_ingest/validate_bag'
require 'spec_helper'

describe Sdr::ValidateBag do

  before(:all) do
    @druid = "druid:jc837rq9922"
    deposit_object = DepositObject.new(@druid)
    @bag_pathname = deposit_object.bag_pathname(validate=false)
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
    @vb.should_receive(:validate_bag_structure).with(@druid, @bag_pathname)
    @vb.should_receive(:validate_bag_data).with(@druid, @bag_pathname)
    Pathname.any_instance.should_receive(:directory?).and_return(true)
    @vb.validate_bag(@druid)
  end

  specify "ValidateBag#validate_bag_structure" do
    @bag_pathname.stub(:to_s).and_return('bagdir')
    @bag_pathname.stub(:directory?).and_return(false)
    lambda{@vb.validate_bag_structure(@druid, @bag_pathname)}.should raise_exception(/bagdir does not exist/)
    @bag_pathname.stub(:directory?).and_return(true)

    data_dir = mock('datadir')
    @bag_pathname.stub(:join).with('data').and_return(data_dir)
    data_dir.stub(:to_s).and_return('datadir')
    data_dir.stub(:directory?).and_return(false)
    lambda{@vb.validate_bag_structure(@druid, @bag_pathname)}.should raise_exception(/datadir does not exist/)
    data_dir.stub(:directory?).and_return(true)

    bagit_txt_file = mock('bagit_txt_file')
    @bag_pathname.stub(:join).with('bagit.txt').and_return(bagit_txt_file)
    bagit_txt_file.stub(:to_s).and_return('bagit_txt_file')
    bagit_txt_file.stub(:file?).and_return(false)
    lambda{@vb.validate_bag_structure(@druid, @bag_pathname)}.should raise_exception(/bagit_txt_file does not exist/)
    bagit_txt_file.stub(:file?).and_return(true)

    bag_info_txt_file = mock('bag_info_txt_file')
    @bag_pathname.stub(:join).with('bag-info.txt').and_return(bag_info_txt_file)
    bag_info_txt_file.stub(:to_s).and_return('bag_info_txt_file')
    bag_info_txt_file.stub(:file?).and_return(false)
    lambda{@vb.validate_bag_structure(@druid, @bag_pathname)}.should raise_exception(/bag_info_txt_file does not exist/)
    bag_info_txt_file.stub(:file?).and_return(true)

    @vb.validate_bag_structure(@druid, @bag_pathname).should == true
  end

  specify "ValidateBag#validate_bag_data" do
    druid = 'druid:jq937jp0017'
    good_bag = @fixtures.join('packages/v0001')
    @vb.validate_bag_data(druid,good_bag ).should == true
    bag_missing_file = @fixtures.join('packages/bag_missing_file')
    lambda{@vb.validate_bag_data(druid,bag_missing_file )}.should raise_exception(LyberCore::Exceptions::ItemError)
    bag_bad_fixity = @fixtures.join('packages/bag_bad_fixity')
    lambda{@vb.validate_bag_data(druid,bag_bad_fixity )}.should raise_exception(LyberCore::Exceptions::ItemError)
  end

  
end
