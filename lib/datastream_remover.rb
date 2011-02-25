require 'nokogiri'
require 'open-uri'

class DatastreamRemover
  
  # @param [String] repository_url e.g., http://fedoraAdmin:fedoraAdmin@sdr-fedora-dev.stanford.edu/fedora
  def initialize(repository_url)    
    @repository_url = repository_url
    Fedora::Repository.register(@repository_url)
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
    return removed_array
  end
  
  # The first time we fetch a batch we don't pass in a sessionToken
  # @param [Integer] the number of PIDs to fetch at one time
  # @param [String] restrict the query to this PID namespace
  def fetch_first_batch(batch_size, pid_namespace)
    url = "#{@repository_url}/objects?terms=#{pid_namespace}*&pid=true&resultFormat=xml&maxResults=#{batch_size}"
    doc = Nokogiri::XML(open(url))
  end
  
  # Given a Nokogiri::XML response from fedora, extract the sessionToken
  # @param [Nokogiri::XML] A nokogiri representation of the XML that fedora sends back from a search query
  # @return [String] the session token required to page through search results
  def extract_session_token(search_results)
    search_results.xpath("/fedora:result/fedora:listSession/fedora:token/text()", 'fedora' => "http://www.fedora.info/definitions/1/0/types/").to_s
  end
  
end