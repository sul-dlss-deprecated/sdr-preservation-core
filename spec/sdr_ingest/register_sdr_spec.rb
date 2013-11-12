require 'sdr_ingest/register_sdr'
require 'spec_helper'

describe Sdr::RegisterSdr do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
    url = ActiveFedora.configurator.fedora_config[:url]
    user = ActiveFedora.configurator.fedora_config[:user]
    password = ActiveFedora.configurator.fedora_config[:password]
    @sedora = url.sub(/[:]\/\//, "://#{user}:#{password}@")
    @druid_url = "#{@sedora}/objects/druid%3A#{@object_id}"
    #    http://fedoraAdmin:fedoraAdmin@localhost:8983/fedora/objects/druid%3Ajc837rq9922?format=xml
  end

  before(:each) do
    @rs = RegisterSdr.new
  end

  specify "RegisterSdr#initialize" do
    @rs.should be_instance_of RegisterSdr
    @rs.should be_kind_of LyberCore::Robots::Robot
    @rs.workflow_name.should == 'sdrIngestWF'
    @rs.workflow_step.should == 'register-sdr'
  end

  specify "RegisterSdr#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rs.should_receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("completed")
    @rs.should_receive(:register_item).with(@druid)
    Dor::WorkflowService.should_receive(:update_workflow_status).with('sdr', @druid, 'sdrIngestWF', 'ingest-cleanup', 'waiting')
    @rs.process_item(work_item)
    @rs.should_receive(:get_workflow_status).with('dor', @druid, 'accessionWF', 'sdr-ingest-transfer').
        and_return("error")
    lambda{@rs.process_item(work_item)}.should raise_exception(/druid:jc837rq9922 - accessionWF:sdr-ingest-transfer status is error/)

  end

  specify "RegisterSdr#register_item existing item with fakeweb" do
    pending "New ActiveFedora has different behavior that affects testing"
    FakeWeb.allow_net_connect = false
    FakeWeb.allow_net_connect = "#{@druid_url}?format=xml"
    FakeWeb.allow_net_connect = "#{@druid_url}/datastreams?format=xml"
    FakeWeb.allow_net_connect = "#{@druid_url}/datastreams/sdrIngestWF?format=xml"
    FakeWeb.allow_net_connect = "#{@druid_url}/datastreams/workflows?format=xml"
    FakeWeb.register_uri(:get, "#{@druid_url}?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/sdrIngestWF?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams/workflows?format=xml", :status => ["200", "OK"])
    @rs.register_item(@druid)
  end

  specify "RegisterSdr#register_item new item with fakeweb" do
    pending "New ActiveFedora has different behavior that affects testing"
#    http://fedoraAdmin:fedoraAdmin@localhost:8983/fedora/objects/druid%3Ajc837rq9922?format=xml
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = true
    #FakeWeb.allow_net_connect = "#{@druid_url}?format=xml"
    #FakeWeb.allow_net_connect = "#{@druid_url}/datastreams?format=xml"
    #FakeWeb.allow_net_connect = "#{@druid_url}/datastreams/sdrIngestWF?format=xml"
    #FakeWeb.allow_net_connect = "#{@druid_url}/datastreams/workflows?format=xml"
    FakeWeb.register_uri(:get, "#{@druid_url}?format=xml", :status => ["404", "no path in db registry for [#{@druid}]"])
    FakeWeb.register_uri(:post, "#{@druid_url}", :status => ["201", "OK"])
    FakeWeb.register_uri(:post, %r|RELS-EXT|, :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "#{@druid_url}/datastreams?format=xml", :status => ["200", "OK"])
    FakeWeb.register_uri(:post, %r|sdrIngestWF[?]dsLocation=|, :status => ["201", "OK"])
    FakeWeb.register_uri(:post, %r|sdrIngestWF[?]controlGroup|, :status => ["201", "OK"])
    FakeWeb.register_uri(:post, %r|workflows[?]dsLocation=|, :status => ["201", "OK"])
    FakeWeb.register_uri(:post, %r|workflows[?]controlGroup|, :status => ["201", "OK"])
    @rs.register_item(@druid)
  end

  specify "RegisterSdr#register_item with mocks" do
    sedora_object = double(SedoraObject)
    SedoraObject.stub(:exists?).with(@druid).and_return(true)
    SedoraObject.should_receive(:find).with(@druid).and_return(sedora_object)
    sedora_object.should_receive(:set_workflow_datastream_location)
    @rs.register_item(@druid)

    SedoraObject.stub(:exists?).with(@druid).and_return(false)
    SedoraObject.should_not_receive(:find)
    SedoraObject.should_receive(:new).with({:pid=>@druid}).and_return(sedora_object)
    sedora_object.should_receive(:save)
    sedora_object.should_receive(:set_workflow_datastream_location)
    @rs.register_item(@druid)

    #def register_item(druid)
    #  LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter register_item")
    #  if SedoraObject.exists?(druid)
    #    sedora_object = SedoraObject.find(druid)
    #  else
    #    sedora_object.new(:pid=>druid)
    #    sedora_object.save
    #  end
    #  sedora_object.set_workflow_datastream_location
    #  sedora_object
    #rescue Exception => e
    #  raise LyberCore::Exceptions::FatalError.new("Sedora Object cannot be found or created", e)
    #end

  end

  it "can add an object to fedora or return nil if object exists" do
    pending "reimplement using mock ActiveFedora objects"
    object = @robot.add_fedora_object(@pid1)
    object.nil?.should eql(false)
    object.should be_instance_of(ActiveFedora::Base)
    ActiveFedora::Base.load_instance(@pid1).should be_true
    # if you try to add an existing object again you'll get nil result, not an exception
    @robot.add_fedora_object(@pid1).should be_nil
  end

  it "can retrieve an already existing object" do
    pending "reimplement using mock ActiveFedora objects"
    object_in = ActiveFedora::Base.new(:pid => @pid1)
    object_in.save
    object_out = @robot.get_fedora_object(@pid1)
    object_out.should be_instance_of(ActiveFedora::Base)
    object_out.pid.should eql(object_in.pid)
  end

  it "can create a workflow datastream" do
    pending "reimplement using mock ActiveFedora objects"
    fedora_object = ActiveFedora::Base.new(:pid => @pid1)
    fedora_object.save
    @robot.add_workflow_datastream(fedora_object)
    object_out = @robot.get_fedora_object(@pid1)
    object_out.datastreams.keys.should include('sdrIngestWF')
    ds = object_out.datastreams['sdrIngestWF']
    ds.attributes[:dsLabel].should eql('sdrIngestWF')
    ds.attributes[:controlGroup].should eql('E')
  end


end
