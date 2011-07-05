require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdrIngest/register_sdr'
require 'fakeweb'

describe SdrIngest::RegisterSdr do

  context "basic behaviour" do

    it "can be created" do
      x = SdrIngest::RegisterSdr.new()
      x.should be_instance_of(SdrIngest::RegisterSdr)
      x.is_a?(LyberCore::Robots::Robot).should eql(true)
    end

  end

  context "process_item" do


    before(:all) do
      @robot = SdrIngest::RegisterSdr.new()
      # if you do not register SOLR you will get  ActiveFedora::SolrNotInitialized if doing object.delete
      ActiveFedora::SolrService.register(SOLR_URL)
      @pid1 = 'sdrtwo:registerSdrTestObject1'
      @work_item_1 = mock('work_item_1')
      @work_item_1.stub(:druid).and_return(@pid1)
    end

    before(:each) do
      begin
        ActiveFedora::Base.load_instance(@pid1).delete
      rescue Exception => e
        #puts e.message
        #puts e.backtrace
        #puts "could not delete #{@pid1}"
      end
    end

    it "can add an object to fedora or return nil if object exists" do
      object = @robot.add_fedora_object(@pid1)
      object.nil?.should eql(false)
      object.should be_instance_of(ActiveFedora::Base)
      ActiveFedora::Base.load_instance(@pid1).should be_true
      # if you try to add an existing object again you'll get nil result, not an exception
      @robot.add_fedora_object(@pid1).should be_nil
    end

    it "can retrieve an already existing object" do
      object_in = ActiveFedora::Base.new(:pid => @pid1)
      object_in.save
      object_out = @robot.get_fedora_object(@pid1)
      object_out.should be_instance_of(ActiveFedora::Base)
      object_out.pid.should eql(object_in.pid)
    end

    it "can create a workflow datastream" do
      fedora_object = ActiveFedora::Base.new(:pid => @pid1)
      fedora_object.save
      @robot.add_workflow_datastream(fedora_object)
      object_out = @robot.get_fedora_object(@pid1)
      object_out.datastreams.keys.should include('sdrIngestWF')
      ds = object_out.datastreams['sdrIngestWF']
      ds.attributes[:dsLabel].should eql('sdrIngestWF')
      ds.attributes[:controlGroup].should eql('E')
    end

    it "can process a work_item" do
      mock_object = mock('fedora object')
      @work_item_1.should_receive(:druid).and_return(@pid1)
      LyberCore::Log.should_receive(:debug)
      @robot.should_receive(:add_fedora_object).with(@pid1).and_return(mock_object)
      @robot.should_receive(:get_fedora_object).exactly(0).times
      @robot.should_receive(:add_workflow_datastream).with(mock_object)
      @robot.process_item(@work_item_1)
    end

 
  end


end
