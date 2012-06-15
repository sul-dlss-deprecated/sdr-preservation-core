require 'sdr/transfer_object'
require 'spec_helper'

describe Sdr::TransferObject do

  before(:all) do
    @druid = "druid:jc837rq9922"
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
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @to.should_receive(:transfer_object).with(@druid)
    @to.process_item(work_item)
  end

  specify "TransferObject#transfer_object" do
    @to.should_receive(:transfer_bag).with(@druid)
    @to.should_receive(:untar_bag).with(@druid)
    @to.should_receive(:cleanup_tarfile).with(@druid)
    @to.transfer_object(@druid)
  end

  specify "TransferObject#transfer_bag" do

    Pathname.any_instance.stub(:exists?).and_return(true)
    lambda{@to.transfer_bag(@druid)}.should raise_exception(LyberCore::Exceptions::ItemError)

    Pathname.any_instance.stub(:exists?).and_return(false)
    Pathname.any_instance.should_receive(:mkpath)
    LyberCore::Utils::FileUtilities.should_receive(:transfer_object).with(
        "#{@druid}.tar",
        Sdr::Config.dor_export,
        SdrDeposit.bag_pathname(@druid).parent.to_s
    )
    @to.transfer_bag(@druid)

   end

  specify "TransferObject#untar_bag" do

    parent = SdrDeposit.bag_pathname(@druid).parent.to_s
    filename = "#{@druid}.tar"

    @to.should_receive(:system).with("cd #{parent}; tar xf #{filename} --force-local").
        and_return(true)
    @to.untar_bag(@druid)

    @to.should_receive(:system).with("cd #{parent}; tar xf #{filename} --force-local").
        and_return(false)
    lambda{@to.untar_bag(@druid)}.should raise_exception(LyberCore::Exceptions::ItemError)

   end

  specify "TransferObject#cleanup_tarfile" do

    tarfile = mock("tar file pathname")
    SdrDeposit.stub(:tarfile_pathname).with(@druid).and_return(tarfile)

    tarfile.should_receive(:delete)
    @to.cleanup_tarfile(@druid)

    tarfile.should_receive(:delete).and_raise(Exception)
    lambda{@to.cleanup_tarfile(@druid)}.should raise_exception(LyberCore::Exceptions::ItemError)

   end


end
