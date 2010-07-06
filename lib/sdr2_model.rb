class Sdr2Model < ActiveFedora::Base
  
  def to_solr(solr_doc = Solr::Document.new, opts={})
    
    ds = self.datastreams()    
    @identity = Nokogiri::XML(ds['IDENTITY'].content)
    @solr_doc = solr_doc
    
    get_fedora_model
    get_title
    get_agreement_id
    get_tags
    get_format
    
    # unless opts[:model_only]
    #       solr_doc << {SOLR_DOCUMENT_ID.to_sym => pid, solr_name(:system_create, :date) => self.create_date, solr_name(:system_modified, :date) => self.modified_date, solr_name(:active_fedora_model, :symbol) => self.class.inspect}
    #     end
    #     datastreams.each_value do |ds|
    #       # solr_doc = ds.to_solr(solr_doc) if ds.class.included_modules.include?(ActiveFedora::MetadataDatastreamHelper) ||( ds.kind_of?(ActiveFedora::RelsExtDatastream) || ( ds.kind_of?(ActiveFedora::QualifiedDublinCoreDatastream) && !opts[:model_only] )
    #       solr_doc = ds.to_solr(solr_doc) if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::NokogiriDatastream) || ( ds.kind_of?(ActiveFedora::RelsExtDatastream) && !opts[:model_only] )
    #     end
    return @solr_doc
  end
  
  def get_fedora_model
    @solr_doc << { solr_name(:active_fedora_model, :symbol) => self.class.inspect }
  end
  
  def get_title    
    title = @identity.xpath("/identityMetadata/citationTitle/text()")
    @solr_doc << { solr_name(:title, :string) => title }
    @solr_doc << { solr_name(:title, :display) => title }
  end
  
  def get_agreement_id
    @solr_doc << { solr_name(:agreement, :facet) => @identity.xpath("/identityMetadata/agreementId/text()") }
  end
  
  def get_tags 
    @identity.xpath("/identityMetadata/tag").each do |tag|
      @solr_doc << { solr_name(:tag, :facet) => tag.text() }
    end
  end
  
  def get_format
    @solr_doc << { :format => "item" }
  end
  
end