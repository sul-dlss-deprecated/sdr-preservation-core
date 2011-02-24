require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'rubygems'
require 'active-fedora'
require File.join(File.dirname(__FILE__), "..", "..", "lib", "datastream_remover.rb")

describe DatastreamRemover do
  
  def setup
    @repository_url = "http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
  end
  
  def cleanup
    
  end

  context "basic behavior" do
    it "should be able to instantiate" do
      dr = DatastreamRemover.new(@repository_url)
      dr.class.should eql(DatastreamRemover)
    end
  end

end
