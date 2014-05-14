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
    expect(@rr).to be_an_instance_of(RecoveryRestore)
    expect(@rr.class.superclass).to eq(Sdr::SdrRobot)
    expect(@rr).to be_a_kind_of(LyberCore::Robot)
    expect(@rr.workflow_name).to eq('sdrRecoveryWF')
    expect(@rr.workflow_step).to eq('recovery-restore')
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
    verification_result.stub(:verified).and_return(true)
    expect(storage_object).to receive(:verify_object_storage).and_return(verification_result)
    @rr.recovery_restore(@druid)
  end

end
