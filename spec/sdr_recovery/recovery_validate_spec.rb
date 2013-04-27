require 'sdr_recovery/recovery_validate'
require 'spec_helper'

describe Sdr::RecoveryValidate do

  before(:all) do
    @object_id = "jq937jp0017"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rv = RecoveryValidate.new
  end

  specify "RecoveryValidate#initialize" do
    @rv.should be_instance_of RecoveryValidate
    @rv.should be_kind_of LyberCore::Robots::Robot
    @rv.workflow_name.should == 'sdrRecoveryWF'
    @rv.workflow_step.should == 'recovery-validate'
  end

  specify "RecoveryValidate#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rv.should_receive(:recovery_validate).with(@druid)
    @rv.process_item(work_item)
  end
  
  specify "RecoveryValidate#recovery_validate" do
    source_path = @fixtures.join('repository',@object_id)
    recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(@druid.sub('druid:',''))
    FileUtils.cp_r(source_path.to_s,recovery_path.to_s)
    @rv.recovery_validate(@druid).should == true
    recovery_path.rmtree if recovery_path.exist?
  end

end
