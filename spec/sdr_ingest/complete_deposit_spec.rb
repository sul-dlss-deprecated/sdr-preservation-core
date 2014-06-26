require 'sdr_ingest/complete_deposit'
require 'spec_helper'
include Robots::SdrRepo::SdrIngest

describe CompleteDeposit do

  before(:all) do
    @druid = "druid:jc837rq9922"
  end

  before(:each) do
    @cd = CompleteDeposit.new
  end

  specify "CompleteDeposit#initialize" do
    expect(@cd).to be_an_instance_of(CompleteDeposit)
    expect(@cd).to be_a_kind_of(LyberCore::Robot)
    expect(@cd.class.workflow_name).to eq('sdrIngestWF')
    expect(@cd.class.step_name).to eq('complete-deposit')
  end

  specify "CompleteDeposit#perform" do
    mock_so = double(StorageObject)
    mock_path = double(Pathname)
    expect(StorageServices).to receive(:find_storage_object).with(@druid,true).and_return(mock_so)
    expect(mock_so).to receive(:object_pathname).and_return(mock_path)
    expect(mock_path).to receive(:mkpath)
    expect(@cd).to receive(:complete_deposit).with(@druid,mock_so)
    @cd.perform(@druid)
  end

  specify "CompleteDeposit#complete_deposit" do
    storage_object = double(StorageObject)
    new_version = double(StorageObjectVersion)
    expect(storage_object).to receive(:ingest_bag).and_return(new_version)
    result = double(VerificationResult)
    result.stub(:verified).and_return(true)
    expect(new_version).to receive(:verify_version_storage).and_return(result)
    @cd.complete_deposit(@druid,storage_object)
  end

end
