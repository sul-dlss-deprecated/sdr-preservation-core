require 'sdr_migration/migration_metadata'
require 'spec_helper'

describe Sdr::MigrationMetadata do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rs = MigrationMetadata.new
  end

  specify "MigrationMetadata#initialize" do
    @rs.should be_instance_of MigrationMetadata
    @rs.class.superclass.should == PopulateMetadata
    @rs.should be_kind_of LyberCore::Robots::Robot
    @rs.workflow_name.should == 'sdrMigrationWF'
    @rs.workflow_step.should == 'migration-metadata'
  end

  specify "MigrationMetadata#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rs.should_receive(:populate_metadata).with(@druid)
    @rs.process_item(work_item)
  end

end
