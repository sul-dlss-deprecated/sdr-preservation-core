require 'sdr_recovery/recovery_cleanup'
require 'spec_helper'

describe Sdr::RecoveryCleanup do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rc = RecoveryCleanup.new
  end

  specify "RecoveryCleanup#initialize" do
    expect(@rc).to be_an_instance_of(RecoveryCleanup)
    expect(@rc.class.superclass).to eq(Sdr::SdrRobot)
    expect(@rc).to be_a_kind_of(LyberCore::Robot)
    expect(@rc.workflow_name).to eq('sdrRecoveryWF')
    expect(@rc.workflow_step).to eq('recovery-cleanup')
  end

  specify "RecoveryCleanup#perform" do
    expect(@rc).to receive(:recovery_cleanup).with(@druid)
    @rc.perform(@druid)
  end

  specify "RecoveryCleanup#recovery_cleanup" do
    druid = "druid:ab000cd0000"
    recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(druid.sub('druid:',''))
    recovery_path.mkpath
    expect(recovery_path.exist?).to eq(true)
    @rc.recovery_cleanup(druid)
    expect(recovery_path.exist?).to eq(false)
    expect(recovery_path.parent.exist?).to eq(true)
  end

end
