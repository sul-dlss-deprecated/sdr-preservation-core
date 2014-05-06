require 'sdr/sdr_robot'
require 'spec_helper'

describe SdrRobot do

  context "SdrRobot adds convenience methods for retrying service requests" do

    before :all do
      @druid = "druid:jc837rq9922"
      @deposit_pathname = @fixtures.join('deposit','jc837rq9922')
    end

    specify "VerifyAgreement#find_deposit_pathname" do
      robot = SdrRobot.new("sdrIngestWF","sdr_robot")
      robot.find_deposit_pathname(@druid).should == @deposit_pathname
      lambda{robot.find_deposit_pathname("druid:aa111bb2222")}.should raise_exception(/pathname does not exist or is not a directory/)
    end

    specify "SdrRobot.transmit" do
      robot = SdrRobot.new("sdrIngestWF","sdr_robot")
      robot.transmit { robot.collection_name = 'test'}
      robot.collection_name.should == 'test'
    end

    specify "SdrRobot.update_workflow_status success" do
      params = ['dor', 'druid', 'accessionWF', 'sdr-ingest-received', 'completed']
      Dor::WorkflowService.should_receive(:update_workflow_status).with(*params).twice.and_raise(TimeoutError)
      Dor::WorkflowService.should_receive(:update_workflow_status).with(*params)
      opts = {:interval => 3}
      params << opts
      robot = SdrRobot.new("sdrIngestWF","sdr_robot")
      robot.update_workflow_status(*params).should == nil
    end

    specify "SdrRobot.update_workflow_status failure" do
      params = ['dor', 'druid', 'accessionWF', 'sdr-ingest-received', 'completed']
      Dor::WorkflowService.should_receive(:update_workflow_status).with(*params).exactly(3).times.and_raise(TimeoutError)
      opts = {:interval => 3}
      params << opts
      robot = SdrRobot.new("sdrIngestWF","sdr_robot")
      lambda{robot.update_workflow_status(*params)}.should raise_exception(LyberCore::Exceptions::FatalError)
    end

  end

end
