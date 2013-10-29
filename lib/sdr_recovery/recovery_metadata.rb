require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'
require 'sdr_ingest/populate_metadata'

module Sdr

  # A robot for ensuring that Sedora contain the expected datastreams for the restored object
  class RecoveryMetadata < PopulateMetadata

    @workflow_name = 'sdrRecoveryWF'
    @workflow_step = 'recovery-metadata'

    # @param druid [String] The object identifier
    # @param bag_pathname [Pathname] The location of the BagIt bag being ingested
    # @return [SedoraObject] Add metadata datastreams to the Fedora object
    def populate_metadata(druid,bag_pathname)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter populate_metadata")
      storage_object = StorageServices.storage_object(druid)
      current_version = storage_object.current_version
      sedora_object = Sdr::SedoraObject.find(druid)
      self.metadata_datastreams.each do |dsid|
        set_datastream_content(sedora_object, current_version, dsid)
      end
      sedora_object.save
      sedora_object
    rescue ActiveFedora::ObjectNotFoundError => e
      raise LyberCore::Exceptions::FatalError.new("Cannot find object #{druid}",e)
    rescue  Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot process item #{druid}",e)
    end

    # @return [Array<String>] The list of datastream IDs that should be saved to sedora
    def metadata_datastreams
      md = Array.new
      md << 'identityMetadata'
      md << 'versionMetadata'
      md << 'provenanceMetadata'
      md << 'relationshipMetadata'
      md
    end

    # @param sedora_object [SedoraObject] The Fedora object to which datatream content is to be saved
    # @param current_version [Object] The version that is used to locate the metadata file
    # @param dsid [String] The datastream identifier, which is also the basename of the XML data file
    # @return [void] Perform the following steps:
    #   - Determine the metadata files full path in the bagit object,
    #   - determine if the metadata file exists, and if so
    #   - copy the content of the metadata file to the datastream.
    # @raise [LyberCore::Exceptions::FatalError] if we can't find the file
    def set_datastream_content(sedora_object, current_version, dsid)
      filepath = current_version.find_filepath('metadata', "#{dsid}.xml")
      if filepath.exist?
        sedora_object.datastreams[dsid].content = filepath.read
        LyberCore::Log.info("datastream #{dsid} content set from #{filepath}")
      else
        LyberCore::Log.info("datastream #{dsid} not set because #{filepath} does not exist")
      end
    rescue Moab::FileNotFoundException
      LyberCore::Log.info("datastream #{dsid} not set because metadata file was not found")
    end

    def verification_queries(druid)
      user_password = "#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}"
      fedora_url = Sdr::Config.sedora.url.sub('//',"//#{user_password}@")
      queries = []
      queries << [
        "#{fedora_url}/objects/#{druid}/datastreams?format=xml",
        200, /versionMetadata/ ]
      queries
    end

    def verification_files(druid)
      files = []
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::RecoveryMetadata.new()
  dm_robot.start
end