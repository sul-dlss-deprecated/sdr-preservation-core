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
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @vb.should_receive(:validate_bag).with(@druid)
    @vb.process_item(work_item)
  end

  specify "ValidateBag#validate_bag" do
    @vb.should_receive(:verify_bag_structure).with(@bag_pathname)
    @vb.should_receive(:verify_version_number).with(@druid,@bag_pathname)
    @vb.should_receive(:validate_bag_data).with(@bag_pathname)
    Pathname.any_instance.should_receive(:directory?).and_return(true)
    @vb.validate_bag(@druid)
  end

  specify "ValidateBag#validate_bag_structure" do
    @bag_pathname.stub(:to_s).and_return('bagdir')
    @bag_pathname.stub(:directory?).and_return(false)
    lambda{@vb.verify_bag_structure(@bag_pathname)}.should raise_exception(/jc837rq9922 not found at bagdir/)
    @bag_pathname.stub(:exist?).and_return(true)

    data_dir = double('datadir')
    @bag_pathname.stub(:join).with('data').and_return(data_dir)
    data_dir.stub(:to_s).and_return('datadir')
    data_dir.stub(:basename).and_return('data')
    data_dir.stub(:exist?).and_return(false)
    lambda{@vb.verify_bag_structure(@bag_pathname)}.should raise_exception(/data not found at datadir/)
    data_dir.stub(:exist?).and_return(true)

    bagit_txt_file = double('bagit_txt_path')
    @bag_pathname.stub(:join).with('bagit.txt').and_return(bagit_txt_file)
    bagit_txt_file.stub(:to_s).and_return('bagit_txt_path')
    bagit_txt_file.stub(:basename).and_return('bagit.txt')
    bagit_txt_file.stub(:exist?).and_return(false)
    lambda{@vb.verify_bag_structure(@bag_pathname)}.should raise_exception(/bagit.txt not found at bagit_txt_path/)
    bagit_txt_file.stub(:exist?).and_return(true)

    bag_info_txt_file = double('bag_info_txt_path')
    @bag_pathname.stub(:join).with('bag-info.txt').and_return(bag_info_txt_file)
    bag_info_txt_file.stub(:to_s).and_return('bag_info_txt_path')
    bag_info_txt_file.stub(:basename).and_return('bag-info.txt')
    bag_info_txt_file.stub(:exist?).and_return(false)
    lambda{@vb.verify_bag_structure(@bag_pathname)}.should raise_exception(/bag-info.txt not found at bag_info_txt_path/)
    bag_info_txt_file.stub(:exist?).and_return(true)

    @bag_pathname.should_receive(:join).exactly(7).times.and_return(double('', :exist? => true))
    @vb.verify_bag_structure(@bag_pathname).should == true
  end

  specify "ValidateBag#validate_bag_data" do
    druid = 'druid:jq937jp0017'
    good_bag = @fixtures.join('packages/v0001')
    @vb.validate_bag_data(good_bag ).should == true
    bag_missing_file = @fixtures.join('packages/bag_missing_file')
    lambda{@vb.validate_bag_data(bag_missing_file )}.should raise_exception(Errno::ENOENT)
    bag_bad_fixity = @fixtures.join('packages/bag_bad_fixity')
    lambda{@vb.validate_bag_data(bag_bad_fixity )}.should raise_exception(/Bag data validation error/)
  end

  specify "ValidateBag#verify_version_number" do
    druid = 'druid:jq937jp0017'
    mock_repository = double(Stanford::StorageRepository)
    Stanford::StorageRepository.should_receive(:new).and_return(mock_repository)
    mock_storage_object = double(Moab::StorageObject)
    mock_repository.should_receive(:storage_object).with(druid,true).and_return(mock_storage_object)
    mock_storage_object.should_receive(:current_version_id).and_return(0)
    bag_pathname = @fixtures.join('packages/v0001')
    @vb.verify_version_number(druid, bag_pathname).should == true
  end

  specify "ValidateBag#verify_version_id" do
    @vb.verify_version_id("/mypath/myfile", expected=2, found=2).should == true
    lambda{@vb.verify_version_id("/mypath/myfile", expected=1, found=2)}.should
      raise_exception("Version mismatch in /mypath/myfile, expected 1, found 2")
  end

  specify "ValidateBag#vmfile_version_id" do
    bag_pathname = @fixtures.join('packages/v0001')
    vmfile = bag_pathname .join("data/metadata/versionMetadata.xml")
    @vb.vmfile_version_id(vmfile).should == 1
  end

  specify "ValidateBag#inventory_version_id" do
    bag_pathname = @fixtures.join('packages/v0001')
    inventory_file = bag_pathname .join("versionAdditions.xml")
    @vb.inventory_version_id(inventory_file).should == 1
  end

end
