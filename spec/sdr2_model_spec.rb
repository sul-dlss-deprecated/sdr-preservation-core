require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdr2_model'

describe Sdr2Model do
  context "adding content to a solr document" do
    
    before(:all) do
      pid = "fixture:fixture1"
      Fedora::Repository.register(SEDORA_URI)
      ActiveFedora::SolrService.register(SOLR_URL)
      filename = File.expand_path(File.dirname(__FILE__) + '/fixtures/fixture_fixture1.foxml.xml')
      puts "Importing '#{filename}' to #{Fedora::Repository.instance.fedora_url}"
      file = File.new(filename, "r")
      result = foxml = Fedora::Repository.instance.ingest(file.read)
      if result
        puts "The fixture has been ingested as #{result}"
      else
        puts "Failed to ingest the fixture"
      end
      @obj = Sdr2Model.load_instance(pid)
      @solr_doc = @obj.to_solr
    end
    
    after(:all) do
      Fedora::Repository.register(SEDORA_URI)
      ActiveFedora::SolrService.register(SOLR_URL)
      pid = "fixture:fixture1"
      puts "Deleting '#{pid}' from #{Fedora::Repository.instance.fedora_url}"
      ActiveFedora::Base.load_instance(pid).delete
      puts "The object has been deleted."
    end
    
    it "should be an instance of Sdr2Model" do
      @obj.should be_instance_of(Sdr2Model)
    end
    
    it "should have a solr document" do
      @solr_doc.should be_instance_of(Solr::Document)
    end
    
    it "should have a solr field called active_fedora_model_s with value Sdr2Model" do
      @solr_doc['active_fedora_model_s'].should == "Sdr2Model"
    end
    
    it "should extract a title" do
      @solr_doc['title_t'].should == "Why go to college?: An address"
    end
    
    
  end
end
