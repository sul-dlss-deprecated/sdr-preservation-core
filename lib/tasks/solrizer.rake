namespace :solrizer do
  
  require 'rubygems'
  require 'solrizer'
  require 'active-fedora'
  require 'sdr2_model.rb'
  
  desc 'Index test'
  task :index do
    pid = 'sdrtwo:jul1alpana3'
    puts "indexing #{pid}"
    SEDORA_USER = 'fedoraAdmin'
    SEDORA_PASS = 'fedoraAdmin'
    SEDORA_URI= "http://#{SEDORA_USER}:#{SEDORA_PASS}@sdr-fedora-dev.stanford.edu/fedora"
    Fedora::Repository.register(SEDORA_URI)
    obj = ActiveFedora::Base.load_instance(PID)
    puts obj.to_solr.inspect
    
    obj.add_relationship(:has_model, "info:fedora/afmodel:Sdr2Model")
    obj.save
    model_klazz_array = ActiveFedora::ContentModel.known_models_for( obj )
    puts model_klazz_array.inspect
    ENV['RAILS_ROOT']='../../../'
    solrizer = Solrizer::Solrizer.new()
    solrizer.solrize(obj)
  end
  
    # 
    # desc 'Index a fedora object of the given pid.'
    # task :solrize do 
    #   index_full_text = ENV['FULL_TEXT'] == 'true'
    #   if ENV['PID']
    #     puts "indexing #{ENV['PID'].inspect}"
    #     solrizer = Solrizer::Solrizer.new :index_full_text=> index_full_text
    #     solrizer.solrize(ENV['PID'])
    #     puts "Finished shelving #{ENV['PID']}"
    #   else
    #     puts "You must provide a pid using the format 'solrizer::solrize_object PID=sample:pid'."
    #   end
    # end
    # 
    # desc 'Index all objects in the repository.'
    # task :solrize_objects do
    #   index_full_text = ENV['FULL_TEXT'] == 'true'
    #   if ENV['INDEX_LIST']
    #     @@index_list = ENV['INDEX_LIST']
    #   end
    #   environment = ENV['ROBOT_ENVIRONMENT']
    #   require File.expand_path(File.dirname(__FILE__) + "/../../config/environments/#{environment}")
    #   puts "Connecting to #{SEDORA_URI}..."
    #   Fedora::Repository.register(SEDORA_URI)
    #   ActiveFedora::SolrService.register(SOLR_URL)
    #   
    #   puts "Re-indexing Fedora Repository."
    #   puts "Fedora URL: #{ActiveFedora.fedora_config[:url]}"
    #   puts "Fedora Solr URL: #{ActiveFedora.solr_config[:url]}"
    #   # puts "Blacklight Solr Config: #{Blacklight.solr_config.inspect}"
    #   puts "Doing full text index." if index_full_text
    #   solrizer = Solrizer::Solrizer.new :index_full_text=> index_full_text
    #   solrizer.solrize_objects
    #   puts "Solrizer task complete."
    # end  
  
end
