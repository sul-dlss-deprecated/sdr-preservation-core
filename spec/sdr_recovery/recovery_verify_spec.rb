require 'sdr_recovery/recovery_verify'
require 'spec_helper'

describe Sdr::RecoveryVerify do

  before(:all) do
    @object_id = "jq937jp0017"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rv = RecoveryVerify.new
  end

  specify "RecoveryVerify#initialize" do
    expect(@rv).to be_an_instance_of(RecoveryVerify)
    expect(@rv).to be_a_kind_of(LyberCore::Robot)
    expect(@rv.workflow_name).to eq('sdrRecoveryWF')
    expect(@rv.workflow_step).to eq('recovery-verify')
  end

  specify "RecoveryVerify#perform" do
    expect(@rv).to receive(:recovery_verify).with(@druid)
    @rv.perform(@druid)
  end
  
  specify "RecoveryVerify#recovery_verify" do
    source_path = @fixtures.join('repository',@object_id)
    recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(@druid.sub('druid:',''))
    FileUtils.cp_r(source_path.to_s,recovery_path.to_s)
    expect(@rv.recovery_verify(@druid)).to eq(true)
    recovery_path.rmtree if recovery_path.exist?
  end

end
