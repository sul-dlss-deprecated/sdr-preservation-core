require 'sdr_ingest/ingest_cleanup'
require 'spec_helper'

describe Sdr::IngestCleanup do

  before(:all) do
    @druid = "druid:jc837rq9922"
  end

  before(:each) do
    @ic = IngestCleanup.new
  end

  specify "IngestCleanup#initialize" do
    expect(@ic).to be_an_instance_of(IngestCleanup)
    expect(@ic).to be_a_kind_of(LyberCore::Robot)
    expect(@ic.class.workflow_name).to eq('sdrIngestWF')
    expect(@ic.class.step_name).to eq('ingest-cleanup')
  end

  specify "IngestCleanup#perform" do
    expect(@ic).to receive(:ingest_cleanup).with(@druid,@fixtures.join('deposit','jc837rq9922'))
    @ic.perform(@druid)
  end

  specify "IngestCleanup#ingest_cleanup" do
    expect_any_instance_of(Pathname).to receive(:exist?).and_return(true)
    expect_any_instance_of(Pathname).to receive(:rmtree)
    expect(Dor::WorkflowService).to receive(:update_workflow_status)
    bag_pathname = @fixtures.join('import','aa111bb2222')
    @ic.ingest_cleanup(@druid,bag_pathname)
  end

end
