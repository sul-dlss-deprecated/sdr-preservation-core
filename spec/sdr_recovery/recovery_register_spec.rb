require 'sdr_recovery/recovery_register'
require 'spec_helper'

describe Sdr::RecoveryRegister do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rr = RecoveryRegister.new
  end

  specify "RecoveryRegister#initialize" do
    @rr.should be_instance_of RecoveryRegister
    @rr.class.superclass.should == RegisterSdr
    @rr.should be_kind_of LyberCore::Robots::Robot
    @rr.workflow_name.should == 'sdrRecoveryWF'
    @rr.workflow_step.should == 'recovery-register'
  end

  specify "RecoveryRegister#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rr.should_receive(:register_item).with(@druid)
    @rr.process_item(work_item)
  end

end
