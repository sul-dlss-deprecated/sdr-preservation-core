require 'sdr_ingest/register_sdr'
require 'spec_helper'

describe Sdr::RegisterSdr do

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
    expect(@rs.workflow_name).to eq('sdrIngestWF')
    expect(@rs.workflow_step).to eq('register-sdr')
  end

  specify "RegisterSdr#perform" do
    expect(@rs).to receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("completed")
    expect(Dor::WorkflowService).to receive(:update_workflow_status).with('sdr', @druid, 'sdrIngestWF', 'ingest-cleanup', 'waiting')
    @rs.perform(@druid)
    expect(@rs).to receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("error")
    expect{@rs.perform(@druid)}.to raise_exception(/druid:jc837rq9922 - accessionWF:sdr-ingest-transfer status is error/)

  end

end
