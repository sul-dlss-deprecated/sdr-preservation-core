require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdrIngest/register_sdr'

describe "connect to sedora" do

  context "Registering SDR Object" do
  it "should be able to connect to sedora" do

    #@robot = GoogleScannedBook::RegisterSdr.new('googleScannedBook', 'register-sdr')
    @robot = SdrIngest::RegisterSdr.new()
    mock_workitem = mock("register_sdr_workitem")
    druid = "sdrtwo:AlpanaTests" + "#{Process.pid}"
    print druid
    mock_workitem.stub!(:druid).and_return(druid)

    puts "About to register"
    Fedora::Repository.register(SEDORA_URI)
    puts "Done register"


    begin
      puts "About to save "
      obj = ActiveFedora::Base.new(:pid => mock_workitem.druid)
      obj.save
      puts "Done save "
    rescue
      $stderr.print $!
    end

  end

  context "basic behaviour" do
   it "can be created" do
      x = SdrIngest::RegisterSdr.new()
      x.should be_instance_of(SdrIngest::RegisterSdr)
    end
  end

  it "should be able to connect to workflow service" do

    

  end
  
  
  describe "#process_druid" do 
    before(:each) do
      @robot = SdrIngest::RegisterSdr.new()
    end
    
    after(:all) do 
        ActiveFedora::Base.load_instance("sdrtwo:registerSdrTestObject1").delete
    end
        
    it "it should register the object in sedora" do 
        @robot.process_druid("sdrtwo:registerSdrTestObject1")
        ActiveFedora::Base.load_instance("sdrtwo:registerSdrTestObject1").should be_true
    end
  
    it "it should raise excpetion if the object is already in fedora" do 
        lambda { @robot.process_druid("sdrtwo:registerSdrTestObject1") }.should raise_error(LyberCore::Exceptions::FatalError)    
    end
  
  end 

  describe "#process_items" do 
    before(:each) do 
      @robot = SdrIngest::RegisterSdr.new()
    end
    
    it "should process all the druids that are returned from the workflow service " do
      DorService.stub!(:get_objects_for_workstep).with("sdr", "sdrIngestWF", "bootstrap", "register-sdr").and_return("<objects count='2' ><object id='sdrtwo:processItemTest1' url='https://dor-prod.stanford.edu/fedora/objects/druid:kd425tz2802' /><object id='sdrtwo:processItemTest2' url='https://dor-prod.stanford.edu/fedora/objects/druid:kd425tz2802' /></objects>")
    
      @robot.should_receive(:process_druid).once.with("sdrtwo:processItemTest1")
      @robot.should_receive(:process_druid).once.with("sdrtwo:processItemTest2")
      
      @robot.process_items
      
    end
    
    it "should raise an error if it cannot extract druids from xml" do 
      DorService.stub!(:get_objects_for_workstep).with("sdr", "sdrIngestWF", "bootstrap", "register-sdr").and_return("A bunch of junk")
      lambda {  @robot.process_items }.should raise_error(LyberCore::Exceptions::FatalError)
    end
    
    it "should raise an error if it cannot connect to the workflow service " do
      lambda { @robot.process_items }.should raise_error(LyberCore::Exceptions::FatalError)
    end
    
  end



  it "should be able to create a workflow" do

  end

end
end
