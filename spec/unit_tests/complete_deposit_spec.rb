require 'sdr/complete_deposit'
require 'spec_helper'

describe Sdr::CompleteDeposit do

  before(:all) do
    @druid = "druid:jc837rq9922"

    @sdr_workflow = %{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workflow objectId="druid:jc837rq9922" id="sdrIngestWF">
      <process lifecycle="inprocess" elapsed="0.0" attempts="0" datetime="2010-06-08T22:09:43-0700" status="completed" name="register-sdr"/>
      <process elapsed="0.158" attempts="1" datetime="2010-06-08T22:14:07-0700" status="completed" name="transfer-object"/>
      <process elapsed="0.104" attempts="1" datetime="2010-06-08T22:16:27-0700" status="completed" name="validate-bag"/>
      <process elapsed="0.481" attempts="1" datetime="2010-06-08T22:19:36-0700" status="completed" name="populate-metadata"/>
      <process elapsed="0.0" attempts="2" datetime="2010-06-21T15:43:33-0700" status="completed" name="verify-agreement"/>
      <process lifecycle="registered" elapsed="0.0" attempts="1" datetime="2010-06-21T15:45:10-0700" status="waiting" name="complete-deposit"/>
      </workflow>}

    @dor_provenance = %{
      <provenanceMetadata objectId="jc837rq9922">
        <agent name="DOR">
          <what object="druid:bp119bq5041">
            <event when="2010-04-06T10:26:52-0700" who="DOR-robot:register-object">Google data received</event>
            <event when="2010-04-23T15:28:41-0700" who="DOR-robot:google-download">Checksums verified</event>
            <event when="2010-04-23T15:30:13-0700" who="DOR-robot: process-content">Image files JHOVE 1.4 validated</event>
          </what>
        </agent>
      </provenanceMetadata>
    }

  end

  before(:each) do
    @cd = CompleteDeposit.new
  end

  specify "CompleteDeposit#initialize" do
    @cd.should be_instance_of CompleteDeposit
    @cd.should be_kind_of LyberCore::Robots::Robot
    @cd.workflow_name.should == 'sdrIngestWF'
    @cd.workflow_step.should == 'complete-deposit'
  end

  specify "CompleteDeposit#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @cd.should_receive(:complete_deposit).with(@druid)
    @cd.process_item(work_item)
  end

  specify "CompleteDeposit#complete_deposit" do
    @cd.repository.should_receive(:store_new_object_version).with(@druid, SdrDeposit.bag_pathname(@druid))
    @cd.repository.should_receive(:verify_version_storage).with(@druid)
    @cd.should_receive(:update_provenance).with(@druid)
    @cd.should_receive(:cleanup_bag).with(@druid)
    @cd.complete_deposit(@druid)
  end

  specify "CompleteDeposit#cleanup_bag" do
    bag_pathname = mock(Pathname)
    SdrDeposit.stub(:bag_pathname).with(@druid).and_return(bag_pathname)
    bag_pathname.should_receive(:rmtree)
    @cd.cleanup_bag(@druid)
  end

  specify "CompleteDeposit#update_provenance" do
    workflow_datastream = mock("sdrIngestWF")
    workflow_datastream.stub(:content).and_return(@sdr_workflow)
    provenance_datastream = mock("provenanceMetadata")
    provenance_datastream.stub(:content).and_return(@dor_provenance)
    sedora_object = mock(SedoraObject)
    sedora_object.stub(:sdrIngestWF).and_return(workflow_datastream)
    sedora_object.stub(:provenanceMetadata).and_return(provenance_datastream)
    Sdr::SedoraObject.stub(:find).with(@druid).and_return(sedora_object)
    provenance_datastream.should_receive(:content=).with(/<provenanceMetadata objectId="jc837rq9922">/)
    provenance_datastream.should_receive(:save)
    @cd.update_provenance(@druid)

    #def update_provenance(druid)
    #  sedora_object = Sdr::SedoraObject.new(:pid=>druid)
    #  workflow_datastream = sedora_object.sdrIngestWF
    #  provenance_datastream = sedora_object.provenanceMetadata
    #  sdr_agent = create_sdr_agent(druid, workflow_datastream.content)
    #  full_provenance = append_sdr_agent(druid, sdr_agent.to_xml, provenance_datastream.content)
    #  provenance_datastream.content = full_provenance.to_xml(:indent=>2)
    #  provenance_datastream.save
    #rescue Exception => e
    #  raise LyberCore::Exceptions::FatalError.new("Cannot update provenanceMetadata datastream for #{druid}",e)
    #end

  end

  specify "CompleteDeposit#create_sdr_provenance" do
    sdr_provenance = @cd.create_sdr_agent(@druid, @sdr_workflow)
    sdr_provenance.should be_an_instance_of Nokogiri::XML::DocumentFragment
    # puts sdr_provenance.to_xml
    sdr_provenance.to_xml.should be_equivalent_to <<-EOF
      <agent name="SDR">
        <what object="druid:jc837rq9922">
          <event who="SDR-robot:register-sdr" when="2010-06-08T22:09:43-0700">druid:jc837rq9922 has been registered in Sedora</event>
          <event who="SDR-robot:transfer-object" when="2010-06-08T22:14:07-0700">druid:jc837rq9922 has been transferred</event>
          <event who="SDR-robot:validate-bag" when="2010-06-08T22:16:27-0700">druid:jc837rq9922 has been validated</event>
          <event who="SDR-robot:populate-metadata" when="2010-06-08T22:19:36-0700">Metadata for druid:jc837rq9922 has been populated in Sedora</event>
          <event who="SDR-robot:verify-agreement" when="2010-06-21T15:43:33-0700">Agreement for druid:jc837rq9922 exists in Sedora</event>
        </what>
      </agent>
    EOF
  end

  specify "CompleteDeposit#append_sdr_provenance" do
    sdr_provenance = @cd.create_sdr_agent(@druid, @sdr_workflow)
    full_provenance = @cd.append_sdr_agent(@druid, sdr_provenance.to_xml, @dor_provenance)
    full_provenance.should be_an_instance_of Nokogiri::XML::Document
    # puts full_provenance.to_xml
    full_provenance.to_xml.should be_equivalent_to <<-EOF
      <provenanceMetadata objectId="jc837rq9922">
        <agent name="DOR">
          <what object="druid:bp119bq5041">
            <event when="2010-04-06T10:26:52-0700" who="DOR-robot:register-object">Google data received</event>
            <event when="2010-04-23T15:28:41-0700" who="DOR-robot:google-download">Checksums verified</event>
            <event when="2010-04-23T15:30:13-0700" who="DOR-robot: process-content">Image files JHOVE 1.4 validated</event>
          </what>
        </agent>
        <agent name="SDR">
          <what object="druid:jc837rq9922">
            <event who="SDR-robot:register-sdr" when="2010-06-08T22:09:43-0700">druid:jc837rq9922 has been registered in Sedora</event>
            <event who="SDR-robot:transfer-object" when="2010-06-08T22:14:07-0700">druid:jc837rq9922 has been transferred</event>
            <event who="SDR-robot:validate-bag" when="2010-06-08T22:16:27-0700">druid:jc837rq9922 has been validated</event>
            <event who="SDR-robot:populate-metadata" when="2010-06-08T22:19:36-0700">Metadata for druid:jc837rq9922 has been populated in Sedora</event>
            <event who="SDR-robot:verify-agreement" when="2010-06-21T15:43:33-0700">Agreement for druid:jc837rq9922 exists in Sedora</event>
          </what>
        </agent>
      </provenanceMetadata>
    EOF
  end

end
