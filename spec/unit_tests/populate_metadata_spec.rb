require 'sdr/populate_metadata'
require 'spec_helper'

describe Sdr::PopulateMetadata do

  before(:all) do
    @druid = "druid:jc837rq9922"

  end

  before(:each) do
     @pm = PopulateMetadata.new
   end

  specify "PopulateMetadata#initialize" do
    @pm.should be_instance_of PopulateMetadata
    @pm.should be_kind_of LyberCore::Robots::Robot
    @pm.workflow_name.should == 'sdrIngestWF'
    @pm.workflow_step.should == 'populate-metadata'
  end

  specify "PopulateMetadata#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @pm.should_receive(:fill_datastreams).with(@druid)
    @pm.process_item(work_item)
  end

  specify "PopulateMetadata#fill_datastreams" do
    bag_pathname = SdrDeposit.bag_pathname(@druid)
    @pm.should_receive(:find_bag).with(@druid).and_return(bag_pathname)
    sedora_object = mock(SedoraObject)
    Sdr::SedoraObject.stub(:find).with(@druid).and_return(sedora_object)
    @pm.should_receive(:set_datastream_content).twice
    sedora_object.should_receive(:save)
    @pm.fill_datastreams(@druid)

    #def fill_datastreams(druid)
    #  LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter populate_metadata")
    #  bag_pathname = find_bag(druid)
    #  sedora_object = Sdr::SedoraObject.find(druid)
    #  set_datastream_content(sedora_object, bag_pathname, 'identityMetadata')
    #  set_datastream_content(sedora_object, bag_pathname, 'provenanceMetadata')
    #  sedora_object.save
    #rescue ActiveFedora::ObjectNotFoundError => e
    #  raise LyberCore::Exceptions::FatalError.new("Cannot find object #{druid}",e)
    #rescue  Exception => e
    #  raise LyberCore::Exceptions::FatalError.new("Cannot process item #{druid}",e)
    #end
  end

  specify "PopulateMetadata#find_bag" do
    bag_pathname = mock("Bag Pathname")
    SdrDeposit.stub(:bag_pathname).with(@druid).and_return(bag_pathname)

    bag_pathname.stub(:directory?).and_return(true)
    @pm.find_bag(@druid)

    bag_pathname.stub(:directory?).and_return(false)
    lambda{@pm.find_bag(@druid)}.should raise_exception(LyberCore::Exceptions::ItemError)

   end

  specify "PopulateMetadata#set_datastream_content" do
    sedora_object = mock(SedoraObject)
    bag_pathname = SdrDeposit.bag_pathname(@druid)
    Pathname.any_instance.stub(:read).and_return('<identityMetadata objectId="druid:jc837rq9922">')
    dsid = 'identityMetadata'
    identity_metatdata = mock(dsid)
    sedora_object.should_receive(:datastreams).and_return({'identityMetadata'=>identity_metatdata})
    identity_metatdata.should_receive(:content=).with(/<identityMetadata objectId="druid:jc837rq9922">/)
    sedora_object.should_not_receive(:pid).and_return(@druid)
    @pm.set_datastream_content(sedora_object, bag_pathname, dsid)

    #def set_datastream_content(sedora_object, bag_pathname, dsid)
    #  LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter set_datastream_content for #{dsid}")
    #  md_pathname = bag_pathname.join('data/metadata',"#{dsid}.xml")
    #  sedora_object.datastreams[dsid].content = md_pathname.read
    #rescue Exception => e
    #  raise LyberCore::Exceptions::FatalError.new("Cannot add #{dsid} datastream for #{sedora_object.pid}",e)
    #end

  end


end
