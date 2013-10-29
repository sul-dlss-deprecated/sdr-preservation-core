require 'sdr_ingest/complete_deposit'
require 'spec_helper'

describe Sdr::CompleteDeposit do

  before(:all) do
    @druid = "druid:jc837rq9922"
    @bag_pathname = @fixtures.join('import','jc837rq9922')
  end

  before(:each) do
    @cd = CompleteDeposit.new
  end

  specify "CompleteDeposit#initialize" do
    @cd.should be_instance_of CompleteDeposit
    @cd.should be_kind_of LyberCore::Robots::Robot
    @cd.workflow_name.should == 'sdrIngestWF'
    @cd.workflow_step.should == 'complete-deposit'
  end

  specify "CompleteDeposit#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    mock_so = mock(StorageObject)
    mock_path = mock(Pathname)
    StorageServices.should_receive(:find_storage_object).with(@druid,true).and_return(mock_so)
    mock_so.should_receive(:object_pathname).and_return(mock_path)
    mock_path.should_receive(:mkpath)
    @cd.should_receive(:complete_deposit).with(@druid,mock_so)
    @cd.process_item(work_item)
  end

  specify "CompleteDeposit#complete_deposit" do
    storage_object = mock(StorageObject)
    new_version = mock(StorageObjectVersion)
    storage_object.should_receive(:ingest_bag).and_return(new_version)
    result = mock(VerificationResult)
    result.stub(:verified).and_return(true)
    new_version.should_receive(:verify_version_storage).and_return(result)
    @cd.complete_deposit(@druid,storage_object)
  end

end
