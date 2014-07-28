require_relative '../libdir'
require 'boot'

module Robots
  module SdrRepo
    module SdrIngest

      # Robot for Validating BagIt bags that are transferred to SDR's deposit area.
      class ValidateBag < SdrRobot

        # class instance variables (accessors defined in SdrRobot parent class)
        @workflow_name = 'sdrIngestWF'
        @step_name = 'validate-bag'

        # @return [ValidateBag] set workflow name, step name, log location, log severity level
        def initialize(opts = {})
          super(self.class.workflow_name, self.class.step_name, opts)
        end

        # @param druid [String] The item to be processed
        # @return [void] process an object from the queue through this robot
        #   See LyberCore::Robot#work
        def perform(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
          validate_bag(druid)
        end

        # @param druid [String] The object identifier
        # @return [Boolean] Validate the bag containing the digital object
        def validate_bag(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter validate_bag")
          storage_object = Replication::SdrObject.new(druid)
          bag = Replication::BagitBag.open_bag(storage_object.deposit_bag_pathname)
          verify_version_number(bag, storage_object.current_version_id)
          bag.verify_bag
          true
        rescue Exception => e
          raise ItemError.new("Bag validation failure", e)
        end

        # @param [Replication::BagitBag] bag the BagIt bag whose versionMetadata is to be verified
        # @param current_version_id [Integer] The version number of the object's current version (or 0 if none)
        # @return [Boolean] Test existence and correct version number of versionMetadata. Return true if OK, raise exception if not
        def verify_version_number(bag, current_version_id)
          expected = current_version_id + 1
          vmfile = bag.bag_pathname.join('data', 'metadata', 'versionMetadata.xml')
          bag.verify_pathname(vmfile)
          verify_version_id(vmfile, expected, vmfile_version_id(vmfile))
          inventory_file = bag.bag_pathname.join('versionAdditions.xml')
          bag.verify_pathname(inventory_file)
          verify_version_id(inventory_file, expected, inventory_version_id(inventory_file))
          inventory_file = bag.bag_pathname.join('versionInventory.xml')
          bag.verify_pathname(inventory_file)
          verify_version_id(inventory_file, expected, inventory_version_id(inventory_file))
          true
        end

        # @param [Pathname] pathname The location of the file containing a version number
        # @param [Integer] expected The version number that should be in the file
        # @param [Integer] found The version number that is actually in the file
        def verify_version_id(pathname, expected, found)
          raise "Version mismatch in #{pathname}, expected #{expected}, found #{found}" unless (expected == found)
          true
        end

        # @param [Pathname] pathname the location of the versionMetadata file
        # @return [Integer] the versionId found in the last version element, or nil if missing
        def vmfile_version_id(pathname)
          doc = Nokogiri::XML(File.open(pathname.to_s))
          nodeset = doc.xpath("/versionMetadata/version")
          version_id = nodeset.last['versionId']
          version_id.nil? ? nil : version_id.to_i
        end

        # @param [Pathname] pathname the location of the inventory file
        # @return [Integer] the versionId found in the last version element, or nil if missing
        def inventory_version_id(pathname)
          doc = Nokogiri::XML(File.open(pathname.to_s))
          nodeset = doc.xpath("/fileInventory")
          version_id = nodeset.first['versionId']
          version_id.nil? ? nil : version_id.to_i
        end

        def verification_queries(druid)
          queries = []
          queries
        end

        def verification_files(druid)
          deposit_bag_pathname = Replication::SdrObject.new(druid).deposit_bag_pathname
          files = []
          files << deposit_bag_pathname.join("bag-info.txt").to_s
          files
        end

      end

    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Robots::SdrRepo::SdrIngest::ValidateBag.new()
  dm_robot.start
end
