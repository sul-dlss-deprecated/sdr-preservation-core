require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'rubygems'
require 'active-fedora'
require 'rest-client'

require File.join(File.dirname(__FILE__), "..", "..", "lib", "datastream_remover.rb")
ENABLE_SOLR_UPDATES = false


describe DatastreamRemover do
  
  context "basic behavior" do
    
    def setup
      @repository_url = "http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
      Fedora::Repository.register(@repository_url)
      
      @solr_url = "http://localhost:8983/solr/"
      @fixture_pid = "fixture:contentmd_removal"
      @fixture_filename = File.join(File.dirname(__FILE__),"..","fixtures","#{@fixture_pid.gsub(":","_")}.foxml.xml")
      
      ActiveFedora::SolrService.register(@solr_url)
      # 
      # # make sure we're starting with a fresh object
      begin
        obj = ActiveFedora::Base.load_instance(@fixture_pid)
        RestClient.delete "#{@repository_url}/objects/#{@fixture_pid}"
      rescue ActiveFedora::ObjectNotFoundError
        # If the object wasn't found, that's fine, don't do anything.
        puts "Object not found"
      rescue
        # But for any other kind of error, let us know what's wrong.
        $stderr.print $!
      end
      
      file = File.new(@fixture_filename, "r")
      result = foxml = Fedora::Repository.instance.ingest(file.read)
      if result
        # puts "The fixture has been ingested as #{result}"  
      else
        raise "Failed to ingest the fixture."
      end
      
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
      dr = DatastreamRemover.new(@repository_url)
      dr.class.should eql(DatastreamRemover)
    end
    
    it "removes a datastream" do
      datastream_name = "contentMetadata"
      batch_size = 1
      pid_namespace = 
      dr = DatastreamRemover.new(@repository_url)
      foo = RestClient.get "#{@repository_url}/objects/#{@fixture_pid}/datastreams/#{datastream_name}?versionable=false"
      foo.code.should eql(200)
      dr.removeDatastream(datastream_name, batch_size, "fixture")
      lambda { RestClient.get "#{@repository_url}/objects/#{@fixture_pid}/datastreams/#{datastream_name}?versionable=false" }.should raise_exception(/404/)      
    end
    
    it "fetches an initial batch of PIDs" do
      dr = DatastreamRemover.new(@repository_url)
      fedora_query_fixture = File.join(File.dirname(__FILE__),"..","fixtures","fedora_query_results.xml")
      first_batch = dr.fetch_batch(1,"fixture")
      first_batch.length.should eql(1)
      first_batch[0].should eql(@fixture_pid)
    end
    
    it "extracts an array of pids from the fedora response" do
      fedora_query_fixture = File.join(File.dirname(__FILE__),"..","fixtures","fedora_query_results.xml")
      doc = Nokogiri::XML(File.open(fedora_query_fixture))
      dr = DatastreamRemover.new(@repository_url)
      pid_array = dr.extract_pid_array(doc)
      pid_array[0].should eql("druid:mh502qk0176")
      pid_array.length.should eql(4)
    end
    
    it "extracts a session token from the fedora response" do
      fedora_query_fixture = File.join(File.dirname(__FILE__),"..","fixtures","fedora_query_results.xml")
      doc = Nokogiri::XML(File.open(fedora_query_fixture))
      dr = DatastreamRemover.new(@repository_url)
      token = dr.extract_session_token(doc)
      token.should eql("bfe62bf233befbff0b9952f44d97f938")
    end
    
  end

end
