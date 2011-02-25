namespace :cleanup do
  
  require File.join(File.dirname(__FILE__), "..", "datastream_remover.rb")
  
  desc "Iterate through all the druids in a repository and remove the content metadata datastream"
  task :remove_content_md do
    repository_url = "http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
    datastream_name = "contentMetadata"
    batch_size = 1
    pid_namespace = "fixture"
    
    dr = DatastreamRemover.new(repository_url)
    dr.removeDatastream(datastream_name, batch_size, pid_namespace)
  end

end