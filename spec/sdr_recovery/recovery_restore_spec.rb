require 'sdr_recovery/recovery_restore'
require 'spec_helper'

describe Sdr::RecoveryRestore do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rr = RecoveryRestore.new
  end

  specify "RecoveryComplete#initialize" do
    @rr.should be_instance_of RecoveryRestore
    @rr.class.superclass.should == Sdr::SdrRobot
    @rr.should be_kind_of LyberCore::Robots::Robot
    @rr.workflow_name.should == 'sdrRecoveryWF'
    @rr.workflow_step.should == 'recovery-restore'
  end

  specify "RecoveryComplete#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rr.should_receive(:recovery_restore).with(@druid)
    @rr.process_item(work_item)
  end

  specify "RecoveryComplete#recovery_restore" do
    repository = mock(Stanford::StorageRepository)
    storage_object = mock(Moab::StorageObject)
    recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(@druid.sub('druid:',''))
    Stanford::StorageRepository.should_receive(:new).and_return(repository)
    repository.should_receive(:storage_object).with(@druid,true).and_return(storage_object)
    storage_object.should_receive(:restore_object).with(recovery_path)
    verification_result = mock(VerificationResult)
    verification_result.stub(:verified).and_return(true)
    storage_object.should_receive(:verify_object_storage).and_return(verification_result)
    @rr.recovery_restore(@druid)
  end

end
