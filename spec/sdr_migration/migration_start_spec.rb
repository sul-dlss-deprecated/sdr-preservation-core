require 'sdr_migration/migration_start'
require 'spec_helper'

describe Sdr::MigrationStart do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @robot = MigrationStart.new
  end

  specify "MigrationStart#initialize" do
    @robot.should be_instance_of MigrationStart
    @robot.should be_kind_of LyberCore::Robots::Robot
    @robot.workflow_name.should == 'sdrMigrationWF'
    @robot.workflow_step.should == 'migration-start'
  end

  specify "MigrationStart#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @robot.should_receive(:create_migration_workflow).with(@druid)
    @robot.process_item(work_item)
  end

  specify "MigrationStart#read_sdr_migration_workflow_xml" do
    wf_xml = @robot.read_sdr_migration_workflow_xml()
    wf_xml.should =~ /<workflow id=\"sdrMigrationWF\">/
  end

end
