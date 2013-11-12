require 'sdr_migration/migration_register'
require 'spec_helper'

describe Sdr::MigrationRegister do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rs = MigrationRegister.new
  end

  specify "MigrationRegister#initialize" do
    @rs.should be_instance_of MigrationRegister
    @rs.class.superclass.should == RegisterSdr
    @rs.should be_kind_of LyberCore::Robots::Robot
    @rs.workflow_name.should == 'sdrMigrationWF'
    @rs.workflow_step.should == 'migration-register'
  end

  specify "MigrationRegister#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rs.should_receive(:register_item).with(@druid)
    @rs.process_item(work_item)
  end

end
