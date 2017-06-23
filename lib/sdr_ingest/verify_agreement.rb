require_relative '../libdir'
require 'boot'

module Robots
  module SdrRepo
    module SdrIngest

      # Robot for verifying that an APO or agreement object exists for each object
      class VerifyAgreement < SdrRobot

        # A cache of APO/agreement object identifiers that have already been verified to exist in Sedora
        @@valid_apo_ids = []
        def self.valid_apo_ids
          @@valid_apo_ids
        end

        # class instance variables (accessors defined in SdrRobot parent class)
        @workflow_name = 'sdrIngestWF'
        @step_name = 'verify-agreement'

        # set workflow name, step name, log location, log severity level
        def initialize(opts = {})
          super(self.class.workflow_name, self.class.step_name, opts)
          @valid_apo_ids = Array.new()
        end

        # Process an object from the queue through this robot
        # @param druid [String] The item to be processed
        # @return [void]
        #   See LyberCore::Robot#work
        def perform(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
          verify_agreement(druid)
        end

        # Find the APO identifier in the relationshipMetadata,
        #   and verify that the identifer belongs to a previously ingested object
        # @param druid [String] The object identifier
        # @return [Boolean] true if APO was found, raise exception if verification fails
        def verify_agreement(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter verify_agreement")
          LyberCore::Log.debug("Druid being processed is #{druid}")
          deposit_pathname = Replication::SdrObject.new(druid).deposit_bag_pathname
          if relationship_md_pathname = find_relationship_metadata(deposit_pathname)
            if apo_id = find_apo_id(druid, relationship_md_pathname)
              if verify_apo_id(druid, apo_id)
                LyberCore::Log.debug("APO id #{apo_id} was verified")
                true
              else
                raise ItemError.new("APO object #{apo_id} was not found in repository")
              end
            else
              raise ItemError.new("APO ID not found in relationshipMetadata")
            end
          else
            version = find_deposit_version(druid, deposit_pathname)
            if version > 1
              LyberCore::Log.debug("APO verification skipped for version > 1")
              true
            else
              raise ItemError.new("relationshipMetadata.xml not found in deposited metadata files")
            end
          end
        end

        def find_relationship_metadata(deposit_pathname)
          relationship_md_pathname = deposit_pathname.join('data', 'metadata', 'relationshipMetadata.xml')
          relationship_md_pathname.file? ? relationship_md_pathname : nil
        end

        # Find the location of the file containing the relationshipMetadata
        # @param [String] druid The object identifier
        # @param [Pathname] deposit_pathname The location of the deposited object version
        # @return [Pathname] The location of the relationshipMetadata.xml file, or raise exception
        def find_deposit_version(druid, deposit_pathname)
          vmfile = deposit_pathname.join('data', 'metadata', 'versionMetadata.xml')
          doc = Nokogiri::XML(vmfile.read)
          nodeset = doc.xpath("/versionMetadata/version")
          version_id = nodeset.last['versionId']
          raise "version_id is nil" if version_id.nil?
          version_id.to_i
        rescue Exception => e
          raise ItemError.new("Unable to find deposit version", e)
        end

        # Extract the APO id from the relationship metadata
        # @param [String] druid The object identifier
        # @param relationship_md_pathname [Pathname] The location of the relationshipMetadata.xml file
        # @return [String] The 'isGovernedBy' APO identifier found in the relationshipMetadata,
        #   or raise exception
        def find_apo_id(druid, relationship_md_pathname)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter find_apo_id")
          relationship_md = Nokogiri::XML(relationship_md_pathname.read)
          nodeset = relationship_md.xpath("//hydra:isGovernedBy", 'hydra' => 'http://projecthydra.org/ns/relations#')
          unless nodeset.empty?
            apo_id = nodeset.first.attribute_with_ns('resource', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')
            if apo_id
              return apo_id.text.split('/')[-1]
            else
              raise ItemError.new("Unable to find resource attribute in isGovernedBy node of relationshipMetadata")
            end
          else
            raise ItemError.new("Unable to find isGovernedBy node of relationshipMetadata")
          end
        rescue Exception => e
          raise ItemError.new("Unable to find APO id in relationshipMetadata", e)
        end

        # Confirm that the APO identifier for the object corresponds to an already ingested object
        # @param [String] druid The object identifier
        # @param apo_druid [String] The APO identifier
        # @return [Boolean] Return true if the object for the apo_druid is found in storage, or raise exception
        def verify_apo_id(druid, apo_druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter verify_identifier")
          if @@valid_apo_ids.include?(apo_druid)
            true
          else
            apo_object = Moab::StorageServices.find_storage_object(apo_druid)
            if apo_object.object_pathname.directory?
              @@valid_apo_ids << apo_druid
              true
            else
              raise ItemError.new("APO object #{apo_druid} not found")
            end
          end
        rescue Exception => e
          raise ItemError.new("Unable to verify APO object #{apo_druid}", e)
        end

        def verification_queries(druid)
          queries = []
          queries
        end

        def verification_files(druid)
          files = []
          files
        end

      end

    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  ARGF.each do |druid|
    dm_robot = Robots::SdrRepo::SdrIngest::VerifyAgreement.new()
    dm_robot.process_item(druid)
  end
end
