
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'googleScannedBook/register_sdr'



describe "connect to sedora" do

  context "Registering SDR Object" do
  it "should be able to connect to sedora" do

    @robot = GoogleScannedBook::RegisterSdr.new('googleScannedBook', 'register-sdr')
    mock_workitem = mock("register_sdr_workitem")
    mock_workitem.stub!(:druid).and_return("druid:sdrtwoAlpanaTests")

    Fedora::Repository.register(SEDORA_URI)


    begin
      obj = ActiveFedora::Base.new(:pid => mock_workitem.druid)
      obj.save
    rescue
      $stderr.print $!
    end

  end

  context "basic behaviour" do
   it "can be created" do
      x = SdrIngest::RegisterSdr.new('googleScannedBook', 'register-sdr')
      x.should be_instance_of(SdrIngest::RegisterSdr)
    end
  end

  it "should be able to connect to workflow service" do

    

  end

  it "should be able to create a workflow" do

  end

end
