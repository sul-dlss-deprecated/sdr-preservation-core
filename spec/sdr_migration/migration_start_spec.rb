require 'sdr_migration/migration_start'
require 'spec_helper'
include Robots::SdrRepo::SdrMigration

describe MigrationStart do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @robot = MigrationStart.new
  end

  specify "MigrationStart#initialize" do
    expect(@robot).to be_an_instance_of(MigrationStart)
    expect(@robot).to be_a_kind_of(LyberCore::Robot)
    expect(@robot.class.workflow_name).to eq('sdrMigrationWF')
    expect(@robot.class.step_name).to eq('migration-start')
  end

  specify "MigrationStart#perform" do
    expect(@robot).to receive(:create_migration_workflow).with(@druid)
    @robot.perform(@druid)
  end

  specify "MigrationStart#read_sdr_migration_workflow_xml" do
    wf_xml = @robot.read_sdr_migration_workflow_xml()
    expect(wf_xml).to match(/<workflow id=\"sdrMigrationWF\">/)
  end

end
