
module Sdr

  class SedoraObject < ::ActiveFedora::Base

#    has_metadata :name => "DC", :type => ActiveFedora::NokogiriDatastream, :label => 'Dublin Core Record for this object'
    has_metadata :name => "identityMetadata", :type => ActiveFedora::NokogiriDatastream, :label => 'Identity Metadata', :control_group => 'M'
#    has_metadata :name => "descMetadata", :type => ActiveFedora::NokogiriDatastream, :label => 'Descriptive Metadata', :control_group => 'M'
#    has_metadata :name => "contentMetadata", :type => ActiveFedora::NokogiriDatastream, :label => 'Content Metadata', :control_group => 'M'
    has_metadata :name => "provenanceMetadata", :type => ActiveFedora::NokogiriDatastream, :label => 'Provenance Metadata', :control_group => 'M'
#    has_metadata :name => "rightsMetadata", :type => ActiveFedora::NokogiriDatastream, :label => 'Rights Metadata', :control_group => 'M'
    has_metadata :name => "relationshipMetadata", :type => ActiveFedora::NokogiriDatastream, :label => 'Relationship Metadata', :control_group => 'M'
    has_metadata :name => "sdrIngestWF", :type => ActiveFedora::NokogiriDatastream, :label => 'Workflow Metadata', :control_group => 'E'
#    has_metadata :name => "workflows", :type => ActiveFedora::NokogiriDatastream, :label => 'Workflows', :control_group => 'E'

    def set_workflow_datastream_location
      if self.sdrIngestWF.new?
        sdrIngestWF.mimeType = 'application/xml'
        sdrIngestWF.dsLocation = File.join(Dor::Config.workflow.url,"dor/objects/#{self.pid}/sdrIngestWF")
        sdrIngestWF.save
      end
      #if self.workflows.new?
      #  workflows.mimeType = 'application/xml'
      #  workflows.dsLocation = File.join(Dor::Config.workflow.url,"dor/objects/#{self.pid}/workflows")
      #  workflows.save
      #end
    end

  end

end
