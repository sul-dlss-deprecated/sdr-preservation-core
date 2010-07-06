require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubygems'
require 'lyber_core'
require 'sdr2_model'

describe Sdr2Model do
  context "adding content to a solr document" do
    
    def setup
    end
    
    it "should add its class" do
      solr_doc << { solr_name(:active_fedora_model, :symbol) => self.class.inspect }
      
    end
    
    it "should extract a title" do
      pending
    end
    
    
  end
end
