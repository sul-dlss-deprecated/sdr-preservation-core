require 'sdr_ingest/transfer_object'
require 'spec_helper'
include Robots::SdrRepo::SdrIngest

describe TransferObject do

  before(:all) do
    @druid = "druid:jc837rq9922"
    @bag_pathname = @fixtures.join('deposit','aa111bb2222')
  end

  before(:each) do
    @to = TransferObject.new
  end

  specify "TransferObject#initialize" do
    expect(@to).to be_an_instance_of(TransferObject)
    expect(@to).to be_a_kind_of(LyberCore::Robot)
    expect(@to.class.workflow_name).to eq('sdrIngestWF')
    expect(@to.class.step_name).to eq('transfer-object')
  end

  specify "TransferObject#perform" do
    expect(@to).to receive(:transfer_object).with(@druid)
    @to.perform(@druid)
  end

  specify "TransferObject#transfer_object" do

    # verify_accesssion_status(druid)
    # verify_dor_export(druid)
    # verify_version_metadata(druid)
    # deposit_home = get_deposit_home(druid)
    # transfer_cmd = tarpipe_command(druid, deposit_home)
    # Archive::OperatingSystem.execute(transfer_cmd)

    Pathname.any_instance.stub(:exist?).and_return(false)
    Pathname.any_instance.stub(:mkpath)
    expect(@to).to receive(:verify_accesssion_status).with(@druid).and_return(true)
    expect(@to).to receive(:verify_dor_export).with(@druid).and_return(true)
    expect(@to).to receive(:verify_version_metadata).with(@druid).and_return(true)
    expect(@to).to receive(:get_deposit_home).with(@druid).and_return(@bag_pathname.parent)
    expect(@to).to receive(:tarpipe_command).with(@druid,@bag_pathname.parent).and_return('thecommand')
    expect(Archive::OperatingSystem).to receive(:execute).with('thecommand')
    @to.transfer_object(@druid)

    expect(@to).to receive(:verify_accesssion_status).with(@druid).and_return(true)
    expect(@to).to receive(:verify_dor_export).with(@druid).and_return(true)
    expect(@to).to receive(:verify_version_metadata).with(@druid).and_return(true)
    expect(@to).to receive(:get_deposit_home).with(@druid).and_return(@bag_pathname.parent)
    expect(@to).to receive(:tarpipe_command).with(@druid,@bag_pathname.parent).and_return('thecommand')
    Archive::OperatingSystem.stub(:execute).and_raise("cmd failed")
    expect{@to.transfer_object(@druid)}.to raise_exception(Robots::SdrRepo::ItemError)

    expect(@to).to receive(:verify_accesssion_status).with(@druid).and_return(true)
    expect(@to).to receive(:verify_dor_export).with(@druid).and_return(true)
    expect(@to).to receive(:verify_version_metadata).with(@druid).and_raise("the error")
    expect{@to.transfer_object(@druid)}.to raise_exception(Robots::SdrRepo::ItemError)

   end

  specify "TransferObject#verify_accesssion_status" do
    expect(@to).to receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("completed")
    @to.verify_accesssion_status(@druid)
    expect(@to).to receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("error")
    expect{@to.verify_accesssion_status(@druid)}.to raise_exception(/accessionWF:sdr-ingest-transfer status is error/)
  end

  specify "TransferObject#verify_dor_export" do
    vmpath = '/dor/export/jc837rq9922'
    expect(@to).to receive(:verify_dor_path).with(vmpath)
    @to.verify_dor_export('druid:jc837rq9922')
  end

  specify "TransferObject#verify_version_metadata" do
    vmpath = '/dor/export/jc837rq9922/data/metadata/versionMetadata.xml'
    expect(@to).to receive(:verify_dor_path).with(vmpath)
    @to.verify_version_metadata('druid:jc837rq9922')
  end

  specify "TransferObject#verify_dor_path" do
    vmpath = '/dor/export/jc837rq9922/data/metadata/versionMetadata.xml'
    vmcmd = "if ssh userid@dor-host.stanford.edu test -e #{vmpath}; then echo exists; else echo notfound; fi"
    expect(Archive::OperatingSystem).to receive(:execute).with(vmcmd).and_return("exists")
    expect(@to.verify_dor_path(vmpath)).to eq(true)
    expect(Archive::OperatingSystem).to receive(:execute).with(vmcmd).and_return("not")
    expect{@to.verify_dor_path(vmpath)}.to raise_exception(/not found/)
  end

  specify "TransferObject#get_deposit_home" do
    # deposit_pathname = Replication::SdrObject.new(druid).deposit_bag_pathname
    # deposit_home = deposit_pathname.parent
    # LyberCore::Log.debug("deposit bag_pathname is : #{deposit_pathname}")
    # if deposit_pathname.exist?
    #   cleanup_deposit_files(druid, deposit_pathname)
    # else
    #   deposit_home.mkpath
    # end
    # deposit_home

    druid = 'druid:jc837rq9922'
    mock_sdr_object = double(Replication::SdrObject)
    deposit_pathname = Pathname('/root/deposit/jc837rq9922')
    expect(Replication::SdrObject).to receive(:new).with(@druid).twice.and_return(mock_sdr_object)
    expect(mock_sdr_object).to receive(:deposit_bag_pathname).twice.and_return(deposit_pathname)

    expect(deposit_pathname).to receive(:exist?).and_return(true)
    expect(@to).to receive(:cleanup_deposit_files).with(druid, deposit_pathname)
    expect(@to.get_deposit_home(druid)).to eq(deposit_pathname.parent)

    expect(deposit_pathname).to receive(:exist?).and_return(false)
    expect_any_instance_of(Pathname).to receive(:mkpath)
    expect(@to.get_deposit_home(druid)).to eq(deposit_pathname.parent)


  end

  specify "TransferObject#tarpipe_command" do
    cmd = @to.tarpipe_command(@druid, "#{ROBOT_ROOT}/spec/fixtures/deposit")
    expect(cmd).to eq( "ssh userid@dor-host.stanford.edu \"tar -C /dor/export/ --dereference -cf - jc837rq9922 \" | tar -C #{ROBOT_ROOT}/spec/fixtures/deposit -xf -")
  end



end
