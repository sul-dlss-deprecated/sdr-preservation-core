require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'deposit/populate_metadata'



describe Deposit::PopulateMetadata do
  
context "Populating Metadata" do
  
  def setup
    @robot = Deposit::PopulateMetadata.new("deposit","populate-metadata")    
    @robot.bag_directory = SDR2_EXAMPLE_OBJECTS
    mock_workitem = mock("populate_metadata_workitem")
    mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
    
    Fedora::Repository.register(SEDORA_URI)
    ActiveFedora::SolrService.register(SOLR_URL)
    
    # Make sure we're starting with a blank object
    begin
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)
      obj.delete
    rescue
      $stderr.print $!
    end
    
    begin
      obj = ActiveFedora::Base.new(:pid => mock_workitem.druid)
      obj.save
    rescue
      $stderr.print $!
    end
  end

  context "dealing with bagit objects" do
    
    before(:each) do
      @robot = Deposit::PopulateMetadata.new("deposit","populate-metadata")    
    end
    
    it "can be created" do
      r = Deposit::PopulateMetadata.new("deposit","populate-metadata")
      r.should be_instance_of(Deposit::PopulateMetadata)
    end
    
    it "can return information about its bag object" do
      @robot.should respond_to(:bag)
    end
    
    it "can tell if the bag exists" do
      @robot.should respond_to(:bag_exists?)
    end
    
    it "knows where to look for the bag object" do
      @robot.should respond_to(:bag_directory)
    end
    
    it "looks in SDR_DEPOSIT_DIR by default" do
      @robot.bag_directory.should eql(SDR_DEPOSIT_DIR)
    end
    
    it "allows us to change the location of bag_directory" do
      @robot.bag_directory = SDR2_EXAMPLE_OBJECTS
      @robot.bag_directory.should eql(SDR2_EXAMPLE_OBJECTS)
    end
    
    it "finds a bag corresponding to the workitem's druid" do
      mock_workitem = mock("populate_metadata_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
      @robot.bag_directory = SDR2_EXAMPLE_OBJECTS
      @robot.process_item(mock_workitem)
      @robot.bag_exists?.should eql(true)
      (File.directory? @robot.bag).should eql(true)
    end
    
    it "raises an IOError if it can't find a bagit object for the given druid" do
	    pending()
#      mock_workitem = mock("populate_metadata_workitem")
#      mock_workitem.stub!(:druid).and_return("druid:obviously_fake")
      
#      lambda { @robot.process_item(mock_workitem) }.should raise_exception(IOError, /Can\'t find a bag/)
    end
  end


  context "processing a workitem" do
    before(:each) do
      setup
    end
    
    
    it "should be able to access a fedora object" do
      @robot.should respond_to(:obj)
    end
    
    it "should have a process_item method" do
      @robot.should respond_to(:process_item)
    end
          
    it "should accept a workitem passed to process_item" do
      mock_workitem = mock("populate_metadata_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
      @robot.process_item(mock_workitem)
    end
    
    # This pre-supposes that process_item has been called
    it "should load a sedora object with the given druid" do
      mock_workitem = mock("populate_metadata_workitem")
      mock_workitem.stub!(:druid).and_return("druid:jc837rq9922")
      @robot.process_item(mock_workitem)
      @robot.obj.should be_instance_of(ActiveFedora::Base)
      @robot.obj.pid.should eql(mock_workitem.druid)
    end    
      
    # pending("If we query sedora with a druid and don't get anything back, what's our fail behavior?")
    it "raises and IOError if it can't l object with the given druid" do
	    pending()
#      mock_workitem = mock("populate_metadata_workitem")
#      mock_workitem.stub!(:druid).and_return("druid:obviously_fake")
#      lambda { @robot.process_item(mock_workitem) }.should raise_exception(IOError, /sedora/)
    
    end
  

    # 
    # it "should throw an error if it can't find the bag object" do
    #   pending("")
    # end
    # 
    # it "should be able to extract the identity metadata from the bag" do
    #   
    # end
    
  end

  context "creating a metadata datastream" do
    before(:each) do
      setup
    end
    
    it "populates identity metadata" do
      
    end
  end
end
end # Populating Metadata
