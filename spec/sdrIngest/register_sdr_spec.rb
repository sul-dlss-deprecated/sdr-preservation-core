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

  it "should be able to create a workflow" do

  end

end
end
