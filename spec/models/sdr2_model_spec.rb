require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdr2_model'

describe Sdr2Model do
  context "adding content to a solr document" do
    
    before(:all) do
      pid = "fixture:fixture1"
      Fedora::Repository.register(SEDORA_URI)
      ActiveFedora::SolrService.register(SOLR_URL)
      filename = File.expand_path(File.dirname(__FILE__) + '/../fixtures/fixture_fixture1.foxml.xml')
      file = File.new(filename, "r")
      result = foxml = Fedora::Repository.instance.ingest(file.read)
      @obj = Sdr2Model.load_instance(pid)
      @solr_doc = @obj.to_solr
    end
    
    after(:all) do
      Fedora::Repository.register(SEDORA_URI)
      ActiveFedora::SolrService.register(SOLR_URL)
      pid = "fixture:fixture1"
      ActiveFedora::Base.load_instance(pid).delete
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
    
    it "should extract an agreement id" do
      @solr_doc['agreement_facet'].should == "druid:tx617qp8040"
    end
    
    it "should index tags" do
      @solr_doc['tag_facet'].should == "Google Book : Phase 1"
    end
    
    it "should have a format of item" do
      @solr_doc['format'].should == "item"
    end
    
  end
end
