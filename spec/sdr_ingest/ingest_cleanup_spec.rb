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
    @ic.should be_instance_of IngestCleanup
    @ic.should be_kind_of LyberCore::Robots::Robot
    @ic.workflow_name.should == 'sdrIngestWF'
    @ic.workflow_step.should == 'ingest-cleanup'
  end

  specify "IngestCleanup#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @ic.should_receive(:ingest_cleanup).with(@druid,@fixtures.join('deposit','jc837rq9922'))
    @ic.process_item(work_item)
  end

  specify "IngestCleanup#ingest_cleanup" do
    Pathname.any_instance.should_receive(:exist?).and_return(true)
    Pathname.any_instance.should_receive(:rmtree)
    Dor::WorkflowService.should_receive(:update_workflow_status)
    bag_pathname = @fixtures.join('import','aa111bb2222')
    @ic.ingest_cleanup(@druid,bag_pathname)
  end

end
