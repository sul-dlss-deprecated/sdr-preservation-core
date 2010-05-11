require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'deposit/populate_metadata'

describe Deposit::PopulateMetadata do

  context "processing a workitem" do
    before(:all) do
      # in the test environment, and only when we want to test against the SDR2_EXAMPLE_OBJECTS,
      # have these tests assume that the SDR2_EXAMPLE_OBJECTS dir is the SDR_DEPOSIT_DIR
      @robot = Deposit::PopulateMetadata.new("deposit","populate-metadata")
      @mock_workitem = mock("workitem")
    
      # return druid:jc837rq9922 when work_item.druid is called
      @mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")      
      
      Fedora::Repository.register(SEDORA_URI)
      ActiveFedora::SolrService.register(SOLR_URL)
      
      # Make sure we're starting with a blank object
      begin
        obj = ActiveFedora::Base.load_instance(@mock_workitem.druid)
        obj.delete
      rescue
        $stderr.print $!
      end
      
      begin
        obj = ActiveFedora::Base.new(:pid => @mock_workitem.druid)
        obj.save
      rescue
      end
    end
    
    it "should be able to access a fedora object" do
      @robot.should respond_to(:obj)
    end
    
    it "should be able to access a bag object" do
      @robot.should respond_to(:bag)
    end
    
    it "should have a process_item method" do
      @robot.should respond_to(:process_item)
    end
    
    it "should know where to look for the bag object" do
      @robot.should respond_to(:bag_directory)
    end
    
    it "should look in SDR_DEPOSIT_DIR by default" do
      @robot.bag_directory.should eql(SDR_DEPOSIT_DIR)
    end
    
    it "should allow us to change the location of bag_directory" do
      @robot.bag_directory = SDR2_EXAMPLE_OBJECTS
      @robot.bag_directory.should eql(SDR2_EXAMPLE_OBJECTS)
    end
          
    it "should accept a workitem passed to process_item" do
      @robot.bag_directory = SDR2_EXAMPLE_OBJECTS
      @robot.process_item(@mock_workitem)
    end
    
    # This pre-supposes that process_item has been called
    it "should load a sedora object with the given druid" do
      @robot.process_item(@mock_workitem)
      @robot.obj.should be_instance_of(ActiveFedora::Base)
      @robot.obj.pid.should eql(@mock_workitem.druid)
    end
    
    it "should be able to find a bag corresponding to the workitem's druid" do
      @robot.bag_directory = SDR2_EXAMPLE_OBJECTS
      @robot.process_item(@mock_workitem)
      @robot.bag_exists?.should eql(true)
      (File.directory? @robot.bag).should eql(true)
    end
    
    #   
    # it "should throw an error if it can't find a sedora object with the given druid" do
    #   pending("If we query sedora with a druid and don't get anything back, what's our fail behavior?")
    # end
  

    # 
    # it "should throw an error if it can't find the bag object" do
    #   pending("")
    # end
    # 
    # it "should be able to extract the identity metadata from the bag" do
    #   
    # end
    
  end

 #  it "should transfer an object" do
 # 
 # # create new transferObject
 #     transfer_robot = Deposit::TransferObject.new( "deposit", "transfer-object")
 # # mock out a workitem
 #     mock_workitem = mock("workitem")
 # # return druid:123 when work_item.druid is called
 #     mock_workitem.stub!(:druid).and_return("druid:123")
 # # verify that FileUtilies.transfer_obejct is called
 #     FileUtilities.should_receive(:transfer_object)
 # 
 # # actually call the function we are testing
 #     transfer_robot.process_item(mock_workitem)
 # 
 #   end

end