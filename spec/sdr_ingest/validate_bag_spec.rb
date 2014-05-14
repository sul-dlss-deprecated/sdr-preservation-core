require 'sdr_ingest/validate_bag'
require 'spec_helper'

describe Sdr::ValidateBag do

  before(:all) do
    @druid = "druid:jc837rq9922"
    @bag_pathname = @fixtures.join('deposit','aa111bb2222')
  end

  before(:each) do
    @vb = ValidateBag.new
  end

  specify "ValidateBag#initialize" do
    expect(@vb).to be_an_instance_of(ValidateBag)
    expect(@vb).to be_a_kind_of(LyberCore::Robot)
    expect(@vb.workflow_name).to eq('sdrIngestWF')
    expect(@vb.workflow_step).to eq('validate-bag')
  end

  specify "ValidateBag#perform" do
    expect(@vb).to receive(:validate_bag).with(@druid,@fixtures.join('deposit','jc837rq9922'), 0)
    @vb.perform(@druid)
  end

  specify "ValidateBag#validate_bag" do
    expect(@vb).to receive(:verify_bag_structure).with(@bag_pathname)
    expect(@vb).to receive(:verify_version_number).with(@bag_pathname,0)
    expect(@vb).to receive(:validate_bag_data).with(@bag_pathname)
    @vb.validate_bag(@druid,@bag_pathname,0)
  end

  specify "ValidateBag#validate_bag_structure" do
    @bag_pathname.stub(:to_s).and_return('bagdir')
    @bag_pathname.stub(:exist?).and_return(false)
    expect{@vb.verify_bag_structure(@bag_pathname)}.to raise_exception(/aa111bb2222 not found at bagdir/)
    @bag_pathname.stub(:exist?).and_return(true)

    data_dir = double('datadir')
    @bag_pathname.stub(:join).with('data').and_return(data_dir)
    data_dir.stub(:to_s).and_return('datadir')
    data_dir.stub(:basename).and_return('data')
    data_dir.stub(:exist?).and_return(false)
    expect{@vb.verify_bag_structure(@bag_pathname)}.to raise_exception(/data not found at datadir/)
    data_dir.stub(:exist?).and_return(true)

    bagit_txt_file = double('bagit_txt_path')
    @bag_pathname.stub(:join).with('bagit.txt').and_return(bagit_txt_file)
    bagit_txt_file.stub(:to_s).and_return('bagit_txt_path')
    bagit_txt_file.stub(:basename).and_return('bagit.txt')
    bagit_txt_file.stub(:exist?).and_return(false)
    expect{@vb.verify_bag_structure(@bag_pathname)}.to raise_exception(/bagit.txt not found at bagit_txt_path/)
    bagit_txt_file.stub(:exist?).and_return(true)

    bag_info_txt_file = double('bag_info_txt_path')
    @bag_pathname.stub(:join).with('bag-info.txt').and_return(bag_info_txt_file)
    bag_info_txt_file.stub(:to_s).and_return('bag_info_txt_path')
    bag_info_txt_file.stub(:basename).and_return('bag-info.txt')
    bag_info_txt_file.stub(:exist?).and_return(false)
    expect{@vb.verify_bag_structure(@bag_pathname)}.to raise_exception(/bag-info.txt not found at bag_info_txt_path/)
    bag_info_txt_file.stub(:exist?).and_return(true)

    expect(@bag_pathname).to receive(:join).exactly(7).times.and_return(double('', :exist? => true))
    expect(@vb.verify_bag_structure(@bag_pathname)).to eq(true)
  end

  specify "ValidateBag#validate_bag_data" do
    druid = 'druid:jq937jp0017'
    good_bag = @fixtures.join('deposit/jq937jp0017')
    expect(@vb.validate_bag_data(good_bag )).to eq(true)
    bag_missing_file = @fixtures.join('deposit/bag_missing_file')
    expect{@vb.validate_bag_data(bag_missing_file )}.to raise_exception(Errno::ENOENT)
    bag_bad_fixity = @fixtures.join('deposit/bag_bad_fixity')
    expect{@vb.validate_bag_data(bag_bad_fixity )}.to raise_exception(/Bag data validation error/)
  end

  specify "ValidateBag#verify_version_number" do
    bag_pathname = @fixtures.join('deposit/jq937jp0017')
    expect(@vb.verify_version_number(bag_pathname,0)).to eq(true)
    expect{@vb.verify_version_number( bag_pathname,1)}.to raise_exception(/Version mismatch/)
  end

  specify "ValidateBag#verify_version_id" do
    expect(@vb.verify_version_id("/mypath/myfile", expected=2, found=2)).to eq(true)
    expect{@vb.verify_version_id("/mypath/myfile", expected=1, found=2)}.to raise_exception(
                                      "Version mismatch in /mypath/myfile, expected 1, found 2")
  end

  specify "ValidateBag#vmfile_version_id" do
    bag_pathname = @fixtures.join('deposit/jq937jp0017')
    vmfile = bag_pathname .join("data/metadata/versionMetadata.xml")
    expect(@vb.vmfile_version_id(vmfile)).to eq(1)
  end

  specify "ValidateBag#inventory_version_id" do
    bag_pathname = @fixtures.join('deposit/jq937jp0017')
    inventory_file = bag_pathname .join("versionAdditions.xml")
    expect(@vb.inventory_version_id(inventory_file)).to eq(1)
  end

end
