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
    @rs.should be_instance_of RegisterSdr
    @rs.should be_kind_of LyberCore::Robots::Robot
    @rs.workflow_name.should == 'sdrIngestWF'
    @rs.workflow_step.should == 'register-sdr'
  end

  specify "RegisterSdr#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rs.should_receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("completed")
    Dor::WorkflowService.should_receive(:update_workflow_status).with('sdr', @druid, 'sdrIngestWF', 'ingest-cleanup', 'waiting')
    @rs.process_item(work_item)
    @rs.should_receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("error")
    lambda{@rs.process_item(work_item)}.should raise_exception(/druid:jc837rq9922 - accessionWF:sdr-ingest-transfer status is error/)

  end

end
