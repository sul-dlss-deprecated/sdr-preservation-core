require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'rubygems'
require 'active-fedora'
require 'rest-client'

require File.join(File.dirname(__FILE__), "..", "..", "lib", "datastream_remover.rb")

describe DatastreamRemover do
  
  context "basic behavior" do
    
    def setup
      Fedora::Repository.register(Sdr::Config.sedora.url)
      
      ActiveFedora::SolrService.register(SOLR_URL)
      
      @fixture_pid = "fixture:contentmd_removal"
      @fixture_filename = File.join(File.dirname(__FILE__),"..","fixtures","#{@fixture_pid.gsub(":","_")}.foxml.xml")
          
      # make sure we're starting with a fresh object
      begin
        ActiveFedora::Base.load_instance(@fixture_pid).delete
      rescue ActiveFedora::ObjectNotFoundError
      end
      
      # test to ensure it was deleted
      lambda{ActiveFedora::Base.load_instance(@fixture_pid)}.should raise_exception(ActiveFedora::ObjectNotFoundError)
      
      # now load the fixture 
      file = File.new(@fixture_filename, "r")
      result = foxml = Fedora::Repository.instance.ingest(file.read)      
      raise "Failed to ingest the fixture." unless result
      
    end

    def cleanup

    end
    
    before(:all) do
      setup
    end
    
    after(:all) do
      cleanup
    end
    
    
    it "can instantiate" do
      dr = DatastreamRemover.new(Sdr::Config.sedora.url)
      dr.class.should eql(DatastreamRemover)
    end
    
    it "removes a datastream" do
      datastream_name = "contentMetadata"
      batch_size = 1
      pid_namespace = 
      dr = DatastreamRemover.new(Sdr::Config.sedora.url)
      foo = RestClient.get "#{Sdr::Config.sedora.url}/objects/#{@fixture_pid}/datastreams/#{datastream_name}?versionable=false"
      foo.code.should eql(200)
      dr.removeDatastream(datastream_name, batch_size, "fixture")
      lambda { RestClient.get "#{Sdr::Config.sedora.url}/objects/#{@fixture_pid}/datastreams/#{datastream_name}?versionable=false" }.should raise_exception(/404/)
    end
    
    it "fetches an initial batch of PIDs" do
      dr = DatastreamRemover.new(Sdr::Config.sedora.url)
      fedora_query_fixture = File.join(File.dirname(__FILE__),"..","fixtures","fedora_query_results.xml")
      first_batch = dr.fetch_batch(1,"fixture")
      first_batch.length.should eql(1)
      first_batch[0].should eql(@fixture_pid)
    end
    
    it "extracts an array of pids from the fedora response" do
      fedora_query_fixture = File.join(File.dirname(__FILE__),"..","fixtures","fedora_query_results.xml")
      doc = Nokogiri::XML(File.open(fedora_query_fixture))
      dr = DatastreamRemover.new(Sdr::Config.sedora.url)
      pid_array = dr.extract_pid_array(doc)
      pid_array[0].should eql("druid:mh502qk0176")
      pid_array.length.should eql(4)
    end
    
    it "extracts a session token from the fedora response" do
      fedora_query_fixture = File.join(File.dirname(__FILE__),"..","fixtures","fedora_query_results.xml")
      doc = Nokogiri::XML(File.open(fedora_query_fixture))
      dr = DatastreamRemover.new(Sdr::Config.sedora.url)
      token = dr.extract_session_token(doc)
      token.should eql("bfe62bf233befbff0b9952f44d97f938")
    end
    
  end

end
