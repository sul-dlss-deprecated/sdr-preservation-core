require 'sdr_recovery/recovery_start'
require 'spec_helper'

describe Sdr::RecoveryStart do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @robot = RecoveryStart.new
  end

  specify "RecoveryStart#initialize" do
    @robot.should be_instance_of RecoveryStart
    @robot.should be_kind_of LyberCore::Robots::Robot
    @robot.workflow_name.should == 'sdrRecoveryWF'
    @robot.workflow_step.should == 'recovery-start'
  end

  specify "RecoveryStart#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @robot.should_receive(:create_recovery_workflow).with(@druid)
    @robot.process_item(work_item)
  end

  specify "RecoveryStart#read_sdr_recovery_workflow_xml" do
    wf_xml = @robot.read_sdr_recovery_workflow_xml()
    wf_xml.should =~ /<workflow id=\"sdrRecoveryWF\">/
  end

end
