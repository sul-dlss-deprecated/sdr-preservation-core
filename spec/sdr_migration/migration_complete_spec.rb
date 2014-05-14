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
    expect(@rs).to be_an_instance_of(MigrationComplete)
    expect(@rs.class.superclass).to eq(CompleteDeposit)
    expect(@rs).to be_a_kind_of(LyberCore::Robot)
    expect(@rs.class.workflow_name).to eq('sdrMigrationWF')
    expect(@rs.class.step_name).to eq('migration-complete')
  end

  specify "MigrationComplete#perform" do
    mock_so = double(StorageObject)
    mock_path = double(Pathname)
    expect(StorageServices).to receive(:find_storage_object).with(@druid,true).and_return(mock_so)
    expect(mock_so).to receive(:object_pathname).and_return(mock_path)
    expect(mock_path).to receive(:mkpath)
    expect(@rs).to receive(:complete_deposit).with(@druid,mock_so)
    @rs.perform(@druid)
  end

end
