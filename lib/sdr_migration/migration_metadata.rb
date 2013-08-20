require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'
require 'sdr_ingest/populate_metadata'

module Sdr

  # A robot for ensuring that Sedora contain the expected datastreams for each migrated object
  # Most methods inherit from the populate-metadata's robot class
  class MigrationMetadata < PopulateMetadata

    @workflow_name = 'sdrMigrationWF'
    @workflow_step = 'migration-metadata'

    # @param druid [String] The object identifier
    # @return [SedoraObject] Add the versionMetadata datastream to the Fedora object
    def populate_metadata(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter populate_metadata")
      bag_pathname = DepositObject.new(druid).bag_pathname()
      remediate_version_metadata(druid, bag_pathname)
      sedora_object = Sdr::SedoraObject.find(druid)
      set_datastream_content(sedora_object, bag_pathname, 'versionMetadata')
      sedora_object.save
      sedora_object
    rescue ActiveFedora::ObjectNotFoundError => e
      raise LyberCore::Exceptions::FatalError.new("Cannot find object #{druid}",e)
    rescue  Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot process item #{druid}",e)
    end

    # @param druid [String] The object identifier
    # @param bag_pathname [Pathname] The location of the BagIt bag being ingested
    # @return [void] Add a v1 versionMetadata datastream unless it already exists
    def remediate_version_metadata(druid, bag_pathname)
      vm_pathname = bag_pathname.join('data/metadata',"versionMetadata.xml")
      unless vm_pathname.exist?
        template_pathname = Pathname("#{ROBOT_ROOT}/config/versionMetadata-template.xml")
        vm_pathname.open('w') do |vm|
          vm << template_pathname.read.sub(/druid/,druid)
        end
      end
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
  dm_robot = Sdr::MigrationMetadata.new()
  dm_robot.start
end