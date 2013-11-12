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
    @rc.should be_instance_of RecoveryCleanup
    @rc.class.superclass.should == Sdr::SdrRobot
    @rc.should be_kind_of LyberCore::Robots::Robot
    @rc.workflow_name.should == 'sdrRecoveryWF'
    @rc.workflow_step.should == 'recovery-cleanup'
  end

  specify "RecoveryCleanup#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rc.should_receive(:recovery_cleanup).with(@druid)
    @rc.process_item(work_item)
  end

  specify "RecoveryCleanup#recovery_cleanup" do
    druid = "druid:ab000cd0000"
    recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(druid.sub('druid:',''))
    recovery_path.mkpath
    recovery_path.exist?.should == true
    @rc.recovery_cleanup(druid)
    recovery_path.exist?.should == false
    recovery_path.parent.exist?.should == true
  end

end
