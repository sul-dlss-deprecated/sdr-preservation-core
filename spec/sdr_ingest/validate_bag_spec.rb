require 'sdr_ingest/validate_bag'
require 'spec_helper'
include Robots::SdrRepo::SdrIngest

describe ValidateBag do

  before(:all) do
    @druid = "druid:jq937jp0017"
    @bag_pathname = @fixtures.join('deposit','jq937jp0017')
  end

  before(:each) do
    @vb = ValidateBag.new
  end

  specify "ValidateBag#initialize" do
    expect(@vb).to be_an_instance_of(ValidateBag)
    expect(@vb).to be_a_kind_of(LyberCore::Robot)
    expect(@vb.class.workflow_name).to eq('sdrIngestWF')
    expect(@vb.class.step_name).to eq('validate-bag')
  end

  specify "ValidateBag#perform" do
    expect(@vb).to receive(:validate_bag).with(@druid)
    @vb.perform(@druid)
  end

  specify "ValidateBag#validate_bag" do
    # storage_object = Replication::SdrObject.new(druid)
    # bag = Replication::BagitBag.open_bag(storage_object.deposit_bag_pathname)
    # verify_version_number(bag, storage_object.current_version_id)
    # bag.verify_bag

    mock_bag = double(Replication::BagitBag)
    expect(Replication::BagitBag).to receive(:open_bag).with(@bag_pathname).and_return(mock_bag)
    expect_any_instance_of(Replication::SdrObject).to receive(:current_version_id).and_return(0)
    expect(@vb).to receive(:verify_version_number).with(mock_bag,0).and_return(true)
    expect(mock_bag).to receive(:verify_bag).and_return(true)
    @vb.validate_bag(@druid)
  end

  specify "ValidateBag#verify_version_number" do
    bag = Replication::BagitBag.open_bag(@bag_pathname)
    expect(bag).to receive(:verify_pathname).with(@bag_pathname.join('data', 'metadata', 'versionMetadata.xml'))
    expect(bag).to receive(:verify_pathname).with(@bag_pathname.join('versionInventory.xml'))
    expect(bag).to receive(:verify_pathname).with(@bag_pathname.join('versionAdditions.xml'))
    expect(@vb.verify_version_number(bag,0)).to eq(true)
    expect(bag).to receive(:verify_pathname).with(@bag_pathname.join('data', 'metadata', 'versionMetadata.xml'))
    expect{@vb.verify_version_number(bag,1)}.to raise_exception(/Version mismatch/)
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
