require 'sdr/sdr_robot'
require 'spec_helper'

describe SdrRobot do

  context "SdrRobot adds convenience methods for retrying service requests" do

    before :all do
      @druid = "druid:jc837rq9922"
      @deposit_pathname = @fixtures.join('deposit','jc837rq9922')
      @robot = SdrRobot.new( "sdrIngestWF","sdr_robot")
    end

    specify "SdrRobot#find_deposit_pathname" do
      expect(@robot.find_deposit_pathname(@druid)).to eq( @deposit_pathname)
      expect{@robot.find_deposit_pathname("druid:aa111bb2222")}.to raise_exception(/pathname does not exist or is not a directory/)
    end

    specify "SdrRobot#transmit" do
      expect(@robot.transmit { @robot.test_success }).to eq "success"
      expect{@robot.transmit({interval: 3}) { @robot.test_failure }}.to raise_exception(/failure/)
    end

    specify "SdrRobot#update_workflow_status success" do
      input = ['dor', 'druid', 'accessionWF', 'sdr-ingest-received', 'completed', 5]
      params = input[0..4]
      params << {:elapsed=>5, :note=>Socket.gethostname}
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with(*params).twice.and_raise(TimeoutError)
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with(*params)
      opts = {interval: 1}
      params << opts
      expect(@robot.update_workflow_status(*input, opts)).to eq(nil)
    end

    specify "SdrRobot#update_workflow_status failure" do
      input = ['dor', 'druid', 'accessionWF', 'sdr-ingest-received', 'completed',5]
      params = input[0..4]
      params << {:elapsed=>5, :note=>Socket.gethostname}
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with(*params).exactly(3).times.and_raise(TimeoutError)
      opts = {interval: 1}
      params << opts
      expect{@robot.update_workflow_status(*input, opts)}.to raise_exception(Sdr::FatalError)
    end

  end

end
