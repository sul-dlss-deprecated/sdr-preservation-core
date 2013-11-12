require 'sdr_ingest/populate_metadata'
require 'spec_helper'

describe Sdr::PopulateMetadata do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
    url = ActiveFedora.configurator.fedora_config[:url]
    user = ActiveFedora.configurator.fedora_config[:user]
    password = ActiveFedora.configurator.fedora_config[:password]
    @sedora = url.sub(/[:]\/\//, "://#{user}:#{password}@")
    @druid_url = "#{@sedora}/objects/druid%3A#{@object_id}"

    @bag_pathname = @fixtures.join('import','jc837rq9922')
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
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @pm.should_receive(:populate_metadata).with(@druid,@fixtures.join('packages','jc837rq9922'))
    @pm.process_item(work_item)
  end

  specify "PopulateMetadata#populate_metadata" do
    sedora_object = double(SedoraObject)
    Sdr::SedoraObject.stub(:find).with(@druid).and_return(sedora_object)
    @pm.should_receive(:set_datastream_content).exactly(4).times
    sedora_object.should_receive(:save)
    @pm.populate_metadata(@druid,@bag_pathname)
  end

  specify "PopulateMetadata#set_datastream_content" do
    sedora_object = double(SedoraObject)
    Pathname.any_instance.stub(:file?).and_return(true)
    Pathname.any_instance.stub(:read).and_return('<identityMetadata objectId="druid:jc837rq9922">')
    dsid = 'identityMetadata'
    identity_metatdata = double(dsid)
    sedora_object.should_receive(:datastreams).and_return({'identityMetadata'=>identity_metatdata})
    identity_metatdata.should_receive(:content=).with(/<identityMetadata objectId="druid:jc837rq9922">/)
    sedora_object.should_not_receive(:pid)
    @pm.set_datastream_content(sedora_object, @bag_pathname, dsid)

    #def set_datastream_content(sedora_object, bag_pathname, dsid)
    #  LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter set_datastream_content for #{dsid}")
    #  md_pathname = bag_pathname.join('data/metadata',"#{dsid}.xml")
    #  sedora_object.datastreams[dsid].content = md_pathname.read
    #rescue Exception => e
    #  raise LyberCore::Exceptions::FatalError.new("Cannot add #{dsid} datastream for #{sedora_object.pid}",e)
    #end

  end

  specify "PopulateMetadata#set_datastream_content with fakeweb" do
#    http://fedoraAdmin:fedoraAdmin@localhost:8983/fedora/objects/druid%3Ajc837rq9922?format=xml
    Rubydora::Repository.any_instance.stub(:version => 3.6)
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = true
    #FakeWeb.allow_net_connect = "#{@druid_url}?format=xml"
    #FakeWeb.allow_net_connect = "#{@druid_url}/datastreams?format=xml"
    #FakeWeb.allow_net_connect = "#{@druid_url}/datastreams/sdrIngestWF?format=xml"
    #FakeWeb.allow_net_connect = "#{@druid_url}/datastreams/workflows?format=xml"
    FakeWeb.register_uri(:get, "#{@sedora}/describe?xml=true", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}?format=xml", :status => ["200", "OK"], :body => '<objectProfile />')
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/workflows?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/sdrIngestWF?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/identityMetadata?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/versionMetadata?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/provenanceMetadata?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/relationshipMetadata?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/RELS-EXT?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/RELS-EXT/content", :status => ["200", "OK"])
    FakeWeb.register_uri(:post, %r|identityMetadata|, :status => ["201", "OK"])
    sedora_object = Sdr::SedoraObject.find(@druid)
    Pathname.any_instance.stub(:file?).and_return(true)
    Pathname.any_instance.stub(:read).and_return('<identityMetadata objectId="druid:jc837rq9922">')
    dsid = 'identityMetadata'
    @pm.set_datastream_content(sedora_object, @bag_pathname, dsid)
    sedora_object.save
  end



end
