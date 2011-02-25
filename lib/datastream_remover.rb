require 'nokogiri'
require 'open-uri'
require 'rest-client'

class DatastreamRemover
  
  # @param [String] repository_url e.g., http://fedoraAdmin:fedoraAdmin@sdr-fedora-dev.stanford.edu/fedora
  def initialize(repository_url)    
    @repository_url = repository_url
    Fedora::Repository.register(@repository_url)
    @session_token = false
  end
  
  # We can't query for all of the items with a particular datastream name, because
  # that information isn't indexed anywhere. Instead, we have to iterate through all of the 
  # objects in our repository and check each one for the datastream in question. 
  # @param [String] the name of the datastream we want to remove
  # @param [Integer] the number of PIDs to fetch at one time
  # @param [String] restrict the removal to this PID namespace
  # @return [Array] the list of druids from which the datastream was removed
  # @example 
  # => dr = DatastreamRemover.new(repository_url)
  # => dr.removeDatastream("contentMetadata",10,"druid") 
  # => will remove the contentMetadata datastream from all objects in the druid: PID namespace, 10 objects at a time
  def removeDatastream(datastream_name, batch_size, pid_namespace)
    removed_array = []
    open('/tmp/output', 'w') { |f| 
      not_yet_processed = fetch_batch(batch_size, pid_namespace)
      fetch_more = true
      while(fetch_more)
        not_yet_processed.each do |pid|
          begin
            RestClient.delete "#{@repository_url}/objects/#{pid.to_s}/datastreams/#{datastream_name}?versionable=false"
          rescue
            $stderr.print $!
          end
          f.puts pid
        end
        not_yet_processed = fetch_batch(batch_size, pid_namespace)
        if(not_yet_processed.length == 0) 
          fetch_more = false
        end
      end
    }
  end
  
  # Fetch a batch of PIDs
  # The first time we fetch a batch we don't pass in a sessionToken
  # @param [Integer] the number of PIDs to fetch at one time
  # @param [String] restrict the query to this PID namespace
  def fetch_batch(batch_size, pid_namespace)
    return [] if(@session_token == 0)
    if(@session_token)
      url = "#{@repository_url}/objects?terms=#{pid_namespace}*&pid=true&resultFormat=xml&maxResults=#{batch_size}&sessionToken=#{@session_token}"
    else
      url = "#{@repository_url}/objects?terms=#{pid_namespace}*&pid=true&resultFormat=xml&maxResults=#{batch_size}"
    end
    begin
      doc = Nokogiri::XML(open(url))
    rescue
      return []
    end
    @session_token = extract_session_token(doc)
    return extract_pid_array(doc)
  end
  
  # Given a Nokogiri::XML response from fedora, extract the PIDs and put them an an array
  # @param [Nokogiri::XML] A nokogiri representation of the XML that fedora sends back from a search query
  # @return [Array] An array of the PIDs returned by this fedora query
  def extract_pid_array(search_results)
    pid_array = []
    search_results.xpath("/fedora:result/fedora:resultList/fedora:objectFields/fedora:pid/text()", 'fedora' => "http://www.fedora.info/definitions/1/0/types/").each do |pid_node|
      pid_array << pid_node.to_s
    end
    return pid_array
  end
  
  # Given a Nokogiri::XML response from fedora, extract the sessionToken
  # @param [Nokogiri::XML] A nokogiri representation of the XML that fedora sends back from a search query
  # @return [String] the session token required to page through search results
  def extract_session_token(search_results)
    session_token = search_results.xpath("/fedora:result/fedora:listSession/fedora:token/text()", 'fedora' => "http://www.fedora.info/definitions/1/0/types/").to_s
    if(session_token.empty?)
      return 0
    else
      return session_token
    end
  end
  
end