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
    @rv.should be_instance_of RecoveryVerify
    @rv.should be_kind_of LyberCore::Robots::Robot
    @rv.workflow_name.should == 'sdrRecoveryWF'
    @rv.workflow_step.should == 'recovery-verify'
  end

  specify "RecoveryVerify#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rv.should_receive(:recovery_verify).with(@druid)
    @rv.process_item(work_item)
  end
  
  specify "RecoveryVerify#recovery_verify" do
    source_path = @fixtures.join('repository',@object_id)
    recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(@druid.sub('druid:',''))
    FileUtils.cp_r(source_path.to_s,recovery_path.to_s)
    @rv.recovery_verify(@druid).should == true
    recovery_path.rmtree if recovery_path.exist?
  end

end
