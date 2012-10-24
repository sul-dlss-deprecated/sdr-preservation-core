require 'sdr_migration/migration_transfer'
require 'spec_helper'

describe Sdr::MigrationTransfer do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @rs = MigrationTransfer.new
  end

  specify "MigrationTransfer#initialize" do
    @rs.should be_instance_of MigrationTransfer
    @rs.class.superclass.should == TransferObject
    @rs.should be_kind_of LyberCore::Robots::Robot
    @rs.workflow_name.should == 'sdrMigrationWF'
    @rs.workflow_step.should == 'migration-transfer'
  end

  specify "MigrationTransfer#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rs.should_receive(:transfer_object).with(@druid)
    @rs.process_item(work_item)
  end

end
