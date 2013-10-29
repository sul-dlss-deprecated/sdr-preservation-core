require 'sdr_migration/migration_complete'
require 'spec_helper'

describe Sdr::MigrationComplete do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rs = MigrationComplete.new
  end

  specify "MigrationComplete#initialize" do
    @rs.should be_instance_of MigrationComplete
    @rs.class.superclass.should == CompleteDeposit
    @rs.should be_kind_of LyberCore::Robots::Robot
    @rs.workflow_name.should == 'sdrMigrationWF'
    @rs.workflow_step.should == 'migration-complete'
  end

  specify "MigrationComplete#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    mock_so = mock(StorageObject)
    mock_path = mock(Pathname)
    StorageServices.should_receive(:find_storage_object).with(@druid,true).and_return(mock_so)
    mock_so.should_receive(:object_pathname).and_return(mock_path)
    mock_path.should_receive(:mkpath)
    @rs.should_receive(:complete_deposit).with(@druid,mock_so)
    @rs.process_item(work_item)
  end

end
