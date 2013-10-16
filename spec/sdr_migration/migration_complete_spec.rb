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
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rs.should_receive(:complete_deposit).with(@druid)
    @rs.process_item(work_item)
  end

end
