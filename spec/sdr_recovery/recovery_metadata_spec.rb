require 'sdr_recovery/recovery_metadata'
require 'spec_helper'

describe Sdr::RecoveryMetadata do

  before(:all) do
    @object_id = "jq937jp0017"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rm = RecoveryMetadata.new
  end

  specify "RecoveryMetadata#initialize" do
    @rm.should be_instance_of RecoveryMetadata
    @rm.class.superclass.should == PopulateMetadata
    @rm.should be_kind_of LyberCore::Robots::Robot
    @rm.workflow_name.should == 'sdrRecoveryWF'
    @rm.workflow_step.should == 'recovery-metadata'
  end

  specify "RecoveryMetadata#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rm.should_receive(:populate_metadata).with(@druid)
    @rm.process_item(work_item)
  end

  specify "RecoveryMetadata#populate_metadata" do
    mock_so = double(Sdr::SedoraObject)
    Sdr::SedoraObject.should_receive(:find).with(@druid).and_return(mock_so)
    @rm.should_receive(:set_datastream_content).any_number_of_times
    mock_so.should_receive(:save).once
    @rm.populate_metadata(@druid)
  end


end
