require 'sdr_ingest/complete_deposit'
require 'spec_helper'

describe Sdr::CompleteDeposit do

  before(:all) do
    @druid = "druid:jc837rq9922"
    deposit_object=DepositObject.new(@druid)
    @bag_pathname = deposit_object.bag_pathname(validate=false)
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
    @cd.should_receive(:complete_deposit).with(@druid)
    @cd.process_item(work_item)
  end

  specify "CompleteDeposit#complete_deposit" do
    repository = mock(Stanford::StorageRepository)
    Stanford::StorageRepository.should_receive(:new).and_return(repository)
    new_version = mock(StorageObjectVersion)
    repository.should_receive(:store_new_object_version).with(@druid, @bag_pathname).and_return(new_version)
    result = mock(VerificationResult)
    result.stub(:verified).and_return(true)
    new_version.should_receive(:verify_version_storage).and_return(result)
    Pathname.any_instance.should_receive(:directory?).and_return(true)
    @cd.complete_deposit(@druid)
  end

end
