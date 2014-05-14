require 'sdr_ingest/transfer_object'
require 'spec_helper'

describe Sdr::TransferObject do

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
    expect(@to.workflow_name).to eq('sdrIngestWF')
    expect(@to.workflow_step).to eq('transfer-object')
  end

  specify "TransferObject#perform" do
     expect(@to).to receive(:transfer_object).with(@druid,@fixtures.join('deposit','jc837rq9922'))
    @to.perform(@druid)
  end


  specify "TransferObject#tarpipe_command" do
    cmd = @to.tarpipe_command(@druid, "#{ROBOT_ROOT}/spec/fixtures/deposit")
    expect(cmd).to eq( "ssh lyberadmin@sul-lyberservices-dev.stanford.edu \"tar -C /dor/export/ --dereference -cf - jc837rq9922 \" | tar -C #{ROBOT_ROOT}/spec/fixtures/deposit -xf -")
  end

  specify "TransferObject#verify_version_metadata" do
    vmcmd = 'if ssh lyberadmin@sul-lyberservices-dev.stanford.edu test -e /dor/export/jc837rq9922/data/metadata/versionMetadata.xml; then echo exists; else echo notfound; fi'
    expect(@to).to receive(:shell_execute).with(vmcmd).and_return("exists")
    expect(@to.verify_version_metadata(@druid)).to eq(true)
    expect(@to).to receive(:shell_execute).with(vmcmd).and_return("not")
    expect(@to.verify_version_metadata(@druid)).to eq(false)
  end

  specify "TransferObject#transfer_object" do

    Pathname.any_instance.stub(:exist?).and_return(false)
    Pathname.any_instance.stub(:mkpath)
    expect(@to).to receive(:verify_version_metadata).with(@druid).and_return(true)
    expect(@to).to receive(:tarpipe_command).with(@druid,@bag_pathname.parent).and_return('thecommand')
    expect(@to).to receive(:shell_execute).with('thecommand')
    @to.transfer_object(@druid,@bag_pathname)

    expect(@to).to receive(:verify_version_metadata).with(@druid).and_return(true)
    expect(@to).to receive(:tarpipe_command).with(@druid,@bag_pathname.parent).and_return('thecommand')
    @to.stub(:shell_execute).and_raise("cmd failed")
    expect{@to.transfer_object(@druid,@bag_pathname)}.to raise_exception(Sdr::ItemError)

    expect(@to).to receive(:verify_version_metadata).with(@druid).and_return(false)
    expect{@to.transfer_object(@druid,@bag_pathname)}.to raise_exception(Sdr::ItemError)

   end

end
