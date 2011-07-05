require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdrIngest/register_sdr'

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
      ActiveFedora::SolrService.register(SOLR_URL)
      @pid1 = 'sdrtwo:registerSdrTestObject1'
      @work_item_1 = mock('work_item_1')
    end

    before(:each) do
      begin
        ActiveFedora::Base.load_instance(@pid1).delete
      rescue Exception => e
        puts e.inspect
        puts "could not delete #{@pid1}"
      end
    end

    it "should add an object to fedora" do
      object = @robot.add_fedora_object(@pid1)
      object.nil?.should eql(false)
      object.should be_instance_of(ActiveFedora::Base)
      ActiveFedora::Base.load_instance(@pid1).should be_true
      # if you try to add an existing object again you'll get nil result, not an exception
      @robot.add_fedora_object(@pid1).should be_nil
    end

    it "it should register the object in sedora" do
      @work_item_1.should_receive(:druid).and_return(@pid1)
      @robot.process_item(@work_item_1)
      ActiveFedora::Base.load_instance(@pid1).should be_true
    end


    it "should process all the druids that are returned from the workflow service " do
      pending
      DorService.stub!(:get_objects_for_workstep).with("sdr", "sdrIngestWF", "start-ingest", "register-sdr").and_return("<objects count='2' ><object id='sdrtwo:processItemTest1' url='https://dor-prod.stanford.edu/fedora/objects/druid:kd425tz2802' /><object id='sdrtwo:processItemTest2' url='https://dor-prod.stanford.edu/fedora/objects/druid:kd425tz2802' /></objects>")

      @robot.should_receive(:process_druid).once.with("sdrtwo:processItemTest1")
      @robot.should_receive(:process_druid).once.with("sdrtwo:processItemTest2")

      @robot.process_items

    end

 
  end


end
