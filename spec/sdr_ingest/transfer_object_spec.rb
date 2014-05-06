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
    @to.should be_instance_of TransferObject
    @to.should be_kind_of LyberCore::Robots::Robot
    @to.workflow_name.should == 'sdrIngestWF'
    @to.workflow_step.should == 'transfer-object'
  end

  specify "TransferObject#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @to.should_receive(:transfer_object).with(@druid,@fixtures.join('deposit','jc837rq9922'))
    @to.process_item(work_item)
  end


  specify "TransferObject#tarpipe_command" do
    cmd = @to.tarpipe_command(@druid, "#{ROBOT_ROOT}/spec/fixtures/deposit")
    cmd.should ==  "ssh lyberadmin@sul-lyberservices-dev.stanford.edu \"tar -C /dor/export/ --dereference -cf - jc837rq9922 \" | tar -C #{ROBOT_ROOT}/spec/fixtures/deposit -xf -"
  end

  specify "TransferObject#verify_version_metadata" do
    vmcmd = 'if ssh lyberadmin@sul-lyberservices-dev.stanford.edu test -e /dor/export/jc837rq9922/data/metadata/versionMetadata.xml; then echo exists; else echo notfound; fi'
    LyberCore::Utils::FileUtilities.should_receive(:execute).with(vmcmd).and_return("exists")
    @to.verify_version_metadata(@druid).should == true
    LyberCore::Utils::FileUtilities.should_receive(:execute).with(vmcmd).and_return("not")
    @to.verify_version_metadata(@druid).should == false
  end

  specify "TransferObject#transfer_object" do

    Pathname.any_instance.stub(:exist?).and_return(false)
    Pathname.any_instance.stub(:mkpath)
    @to.should_receive(:verify_version_metadata).with(@druid).and_return(true)
    @to.should_receive(:tarpipe_command).with(@druid,@bag_pathname.parent).and_return('thecommand')
    LyberCore::Utils::FileUtilities.should_receive(:execute).with('thecommand')
    @to.transfer_object(@druid,@bag_pathname)

    @to.should_receive(:verify_version_metadata).with(@druid).and_return(true)
    @to.should_receive(:tarpipe_command).with(@druid,@bag_pathname.parent).and_return('thecommand')
    LyberCore::Utils::FileUtilities.stub!(:execute).and_raise("cmd failed")
    lambda {@to.transfer_object(@druid,@bag_pathname)}.should raise_exception(LyberCore::Exceptions::ItemError)

    @to.should_receive(:verify_version_metadata).with(@druid).and_return(false)
    lambda {@to.transfer_object(@druid,@bag_pathname)}.should raise_exception(LyberCore::Exceptions::ItemError)

   end

end
