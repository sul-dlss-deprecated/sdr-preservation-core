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
    expect(@robot).to be_an_instance_of(RecoveryStart)
    expect(@robot).to be_a_kind_of(LyberCore::Robot)
    expect(@robot.workflow_name).to eq('sdrRecoveryWF')
    expect(@robot.workflow_step).to eq('recovery-start')
  end

  specify "RecoveryStart#perform" do
    expect(@robot).to receive(:create_recovery_workflow).with(@druid)
    @robot.perform(@druid)
  end

  specify "RecoveryStart#read_sdr_recovery_workflow_xml" do
    wf_xml = @robot.read_sdr_recovery_workflow_xml()
    expect(wf_xml).to match(/<workflow id=\"sdrRecoveryWF\">/)
  end

end
