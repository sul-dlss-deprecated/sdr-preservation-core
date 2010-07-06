class Sdr2Model < ActiveFedora::Base
  
  def to_solr(solr_doc = Solr::Document.new, opts={})
    solr_doc << get_fedora_model
    solr_doc << get_title
    
    # unless opts[:model_only]
    #       solr_doc << {SOLR_DOCUMENT_ID.to_sym => pid, solr_name(:system_create, :date) => self.create_date, solr_name(:system_modified, :date) => self.modified_date, solr_name(:active_fedora_model, :symbol) => self.class.inspect}
    #     end
    #     datastreams.each_value do |ds|
    #       # solr_doc = ds.to_solr(solr_doc) if ds.class.included_modules.include?(ActiveFedora::MetadataDatastreamHelper) ||( ds.kind_of?(ActiveFedora::RelsExtDatastream) || ( ds.kind_of?(ActiveFedora::QualifiedDublinCoreDatastream) && !opts[:model_only] )
    #       solr_doc = ds.to_solr(solr_doc) if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::NokogiriDatastream) || ( ds.kind_of?(ActiveFedora::RelsExtDatastream) && !opts[:model_only] )
    #     end
    return solr_doc
  end
  
  def get_fedora_model
    { solr_name(:active_fedora_model, :symbol) => self.class.inspect }
  end
  
  def get_title
    { solr_name(:title, :string) => "Why go to college?: An address" }
  end
  
end