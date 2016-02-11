require 'sdr_ingest/complete_deposit'
require 'spec_helper'

describe Robots::SdrRepo::SdrIngest::CompleteDeposit do

  before(:all) do
    @druid = "druid:jc837rq9922"
  end

  before(:each) do
    @cd = described_class.new
  end

  specify "CompleteDeposit#initialize" do
    expect(@cd).to be_a_kind_of(LyberCore::Robot)
    expect(@cd.class.workflow_name).to eq('sdrIngestWF')
    expect(@cd.class.step_name).to eq('complete-deposit')
  end

  specify "CompleteDeposit#perform" do
    mock_so = double(Moab::StorageObject)
    mock_path = double(Pathname)
    expect(Moab::StorageServices).to receive(:find_storage_object).with(@druid,true).and_return(mock_so)
    expect(mock_so).to receive(:object_pathname).and_return(mock_path)
    expect(mock_path).to receive(:mkpath)
    expect(@cd).to receive(:complete_deposit).with(@druid,mock_so)
    @cd.perform(@druid)
  end

  specify "CompleteDeposit#complete_deposit" do
    storage_object = double(Moab::StorageObject)
    new_version = double(Moab::StorageObjectVersion)
    expect(storage_object).to receive(:ingest_bag).and_return(new_version)
    result = double(Moab::VerificationResult)
    allow(result).to receive(:verified).and_return(true)
    expect(new_version).to receive(:verify_version_storage).and_return(result)
    @cd.complete_deposit(@druid,storage_object)
  end

end
