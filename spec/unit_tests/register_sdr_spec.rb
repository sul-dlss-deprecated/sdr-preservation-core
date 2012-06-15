require 'sdr/register_sdr'
require 'spec_helper'

describe Sdr::RegisterSdr do

  before(:all) do
    @druid = "druid:jc837rq9922"
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
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @rs.should_receive(:register_item).with(@druid)
    @rs.process_item(work_item)
  end

  specify "RegisterSdr#register_item" do

    sedora_object = mock(SedoraObject)
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



end
