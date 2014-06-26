require 'sdr_ingest/register_sdr'
require 'spec_helper'
include Robots::SdrRepo::SdrIngest

describe RegisterSdr do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rs = RegisterSdr.new
  end

  specify "RegisterSdr#initialize" do
    expect(@rs).to be_an_instance_of(RegisterSdr)
    expect(@rs).to be_a_kind_of(LyberCore::Robot)
    expect(@rs.class.workflow_name).to eq('sdrIngestWF')
    expect(@rs.class.step_name).to eq('register-sdr')
  end

  specify "RegisterSdr#perform" do
    expect(@rs).to receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("completed")
    expect(Dor::WorkflowService).to receive(:update_workflow_status)
    @rs.perform(@druid)
    expect(@rs).to receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("error")
    expect{@rs.perform(@druid)}.to raise_exception(/druid:jc837rq9922 - accessionWF:sdr-ingest-transfer status is error/)

  end

end
