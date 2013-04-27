require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'
require 'sdr_ingest/populate_metadata'

module Sdr

  # A robot for ensuring that Sedora contain the expected datastreams for the restored object
  class RecoveryMetadata < PopulateMetadata

    @workflow_name = 'sdrRecoveryWF'
    @workflow_step = 'recovery-metadata'

    # @param druid [String] The object identifier
    # @return [SedoraObject] Add metadata datastreams to the Fedora object
    def populate_metadata(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter populate_metadata")
      repository = Stanford::StorageRepository.new
      storage_object = repository.storage_object(druid)
      cv = storage_object.current_version
      sedora_object = Sdr::SedoraObject.find(druid)
      self.metadata_datastreams.each do |dsname|
        begin
          filepath = cv.find_filepath('metadata', "#{dsname}.xml")
          set_datastream_content(sedora_object, filepath, dsname)
        rescue Moab::FileNotFoundException
        end
      end
      sedora_object.save
      sedora_object
    rescue ActiveFedora::ObjectNotFoundError => e
      raise LyberCore::Exceptions::FatalError.new("Cannot find object #{druid}",e)
    rescue  Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot process item #{druid}",e)
    end

    def metadata_datastreams
      md = Array.new
      md << 'identityMetadata'
      md << 'versionMetadata'
      md << 'provenanceMetadata'
      md << 'relationshipMetadata'
      md
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