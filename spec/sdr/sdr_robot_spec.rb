require 'sdr/sdr_robot'
require 'spec_helper'
include Robots::SdrRepo

describe SdrRobot do

  context "SdrRobot adds convenience methods for retrying service requests" do

    before :all do
      @druid = "druid:jc837rq9922"
      @deposit_pathname = @fixtures.join('deposit','jc837rq9922')
      @robot = SdrRobot.new( "sdrIngestWF","sdr_robot")
    end

    specify "SdrRobot#transmit" do
      expect(@robot.transmit { "success" }).to eq "success"
      expect{@robot.transmit({interval: 3}) { raise "failure" }}.to raise_exception Robots::SdrRepo::FatalError
    end

    specify "SdrRobot#update_workflow_status success" do
      input = ['dor', 'druid', 'accessionWF', 'sdr-ingest-received', 'completed', 5]
      params = input[0..4]
      opts = {:elapsed=>5, :note=>Socket.gethostname, interval: 1}
      params << opts
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with(*params).twice.and_raise(TimeoutError)
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with(*params)
      expect(@robot.update_workflow_status(*input, opts)).to eq(nil)
    end

    specify "SdrRobot#update_workflow_status failure" do
      input = ['dor', 'druid', 'accessionWF', 'sdr-ingest-received', 'completed',5]
      params = input[0..4]
      opts = {:elapsed=>5, :note=>Socket.gethostname, interval: 1}
      params << opts
      expect(Dor::WorkflowService).to receive(:update_workflow_status).with(*params).exactly(3).times.and_raise(TimeoutError)
      expect{@robot.update_workflow_status(*input, opts)}.to raise_exception(FatalError)
    end

  end

end
