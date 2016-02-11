require 'sdr_recovery/recovery_restore'
require 'spec_helper'
include Robots::SdrRepo::SdrRecovery

describe RecoveryRestore do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rr = RecoveryRestore.new
  end

  specify "RecoveryComplete#initialize" do
    expect(@rr).to be_an_instance_of(RecoveryRestore)
    expect(@rr.class.superclass).to eq(Robots::SdrRepo::SdrRobot)
    expect(@rr).to be_a_kind_of(LyberCore::Robot)
    expect(@rr.class.workflow_name).to eq('sdrRecoveryWF')
    expect(@rr.class.step_name).to eq('recovery-restore')
  end

  specify "RecoveryComplete#perform" do
    expect(@rr).to receive(:recovery_restore).with(@druid)
    @rr.perform(@druid)
  end

  specify "RecoveryComplete#recovery_restore" do
    storage_object = double(Moab::StorageObject)
    recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(@druid.sub('druid:',''))
    expect(StorageServices).to receive(:storage_object).with(@druid,true).and_return(storage_object)
    expect(storage_object).to receive(:restore_object).with(recovery_path)
    verification_result = double(VerificationResult)
    allow(verification_result).to receive(:verified).and_return(true)
    expect(storage_object).to receive(:verify_object_storage).and_return(verification_result)
    @rr.recovery_restore(@druid)
  end

end
