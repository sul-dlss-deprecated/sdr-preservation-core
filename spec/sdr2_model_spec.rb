require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdr2_model'

describe Sdr2Model do
  context "adding content to a solr document" do
    
    before(:all) do
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
    end
    
    after(:all) do
      Fedora::Repository.register(SEDORA_URI)
      ActiveFedora::SolrService.register(SOLR_URL)
      pid = "fixture:fixture1"
      puts "Deleting '#{pid}' from #{Fedora::Repository.instance.fedora_url}"
      ActiveFedora::Base.load_instance(pid).delete
      puts "The object has been deleted."
    end
    
    it "should add its class" do
      pending
      # solr_doc << { solr_name(:active_fedora_model, :symbol) => self.class.inspect }
    end
    
    it "should extract a title" do
      pending
    end
    
    
  end
end
