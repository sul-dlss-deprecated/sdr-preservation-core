require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for Validating BagIt bags that are transferred to SDR's deposit area.
  class ValidateBag < SdrRobot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'validate-bag'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # @return [ValidateBag] set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      storage_object = StorageServices.find_storage_object(work_item.druid,include_deposit=true)
      bag_pathname = storage_object.deposit_bag_pathname
      current_version_id  = storage_object.current_version_id
      validate_bag(work_item.druid,bag_pathname, current_version_id)
    end

    # @param druid [String] The object identifier
    # @param bag_pathname [Pathname] The location of the BagIt bag being ingested
    # @param current_version_id [Integer] The version number of the object's current version (or 0 if none)
    # @return [Boolean] Validate the bag containing the digital object
    def validate_bag(druid, bag_pathname, current_version_id)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter validate_bag")
      verify_bag_structure(bag_pathname)
      verify_version_number(bag_pathname, current_version_id)
      validate_bag_data(bag_pathname)
      true
    rescue Exception => e
      raise LyberCore::Exceptions::ItemError.new(druid, "Bag validation failure", e)
    end

    # @param [Pathname] bag_pathname the location of the bag to be verified
    # @return [Boolean] Test the existence of expected files, return true if files exist, raise exception if not
    def verify_bag_structure(bag_pathname)
      verify_pathname(bag_pathname)
      verify_pathname(bag_pathname.join('data'))
      verify_pathname(bag_pathname.join('bagit.txt'))
      verify_pathname(bag_pathname.join('bag-info.txt'))
      verify_pathname(bag_pathname.join('manifest-sha256.txt'))
      verify_pathname(bag_pathname.join('tagmanifest-sha256.txt'))
      verify_pathname(bag_pathname.join('versionAdditions.xml'))
      verify_pathname(bag_pathname.join('versionInventory.xml'))
      true
    end

    # @param [Pathname] pathname The file whose existence should be verified
    # @return [Boolean] Test the existence of the specified path.  Return true if file exists, raise exception if not
    def verify_pathname(pathname)
      raise "#{pathname.basename} not found at #{pathname}" unless pathname.exist?
      true
    end

    # @param [Pathname] bag_pathname the location of the bag whose versionMetadata is to be verified
    # @param current_version_id [Integer] The version number of the object's current version (or 0 if none)
    # @return [Boolean] Test existence and correct version number of versionMetadata. Return true if OK, raise exception if not
    def verify_version_number(bag_pathname, current_version_id)
      expected = current_version_id + 1
      vmfile = bag_pathname.join('data','metadata','versionMetadata.xml')
      verify_version_id(vmfile, expected, vmfile_version_id(vmfile))
      inventory_file = bag_pathname.join('versionAdditions.xml')
      verify_version_id(inventory_file, expected, inventory_version_id(inventory_file))
      inventory_file = bag_pathname.join('versionInventory.xml')
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
      verify_pathname(pathname)
      doc = Nokogiri::XML(File.open(pathname.to_s))
      nodeset = doc.xpath("/versionMetadata/version")
      version_id = nodeset.last['versionId']
      version_id.nil? ? nil : version_id.to_i
    end

    # @param [Pathname] pathname the location of the inventory file
    # @return [Integer] the versionId found in the last version element, or nil if missing
    def inventory_version_id(pathname)
      verify_pathname(pathname)
      doc = Nokogiri::XML(File.open(pathname.to_s))
      nodeset = doc.xpath("/fileInventory")
      version_id = nodeset.first['versionId']
      version_id.nil? ? nil : version_id.to_i
    end

    # @param [Pathname] bag_pathname the location of the bag whose data is to be validated
    # @return [Boolean] Use the BagIt gem's validation method to verify checksums
    def validate_bag_data(bag_pathname)
      invalid_signatures = Array.new
      pathname_signature_hash = FileInventory.new.signatures_from_bagit_manifests(bag_pathname)
      pathname_signature_hash.each do |pathname,signature_from_manifest|
        #unless pathname.exist?
        #  invalid_signatures << "File does not exist: #{pathname}"
        #else
          signature_from_file = FileSignature.new.signature_from_file(pathname)
          unless signature_from_file.eql?(signature_from_manifest)
            invalid_signatures << "Checksum inconsistent for: #{pathname}"
            invalid_signatures << "  expected: #{signature_from_manifest.fixity.inspect}"
            invalid_signatures << "  detected: #{signature_from_file.fixity.inspect}"
          end
        #end
      end
      if invalid_signatures.size > 0
        errors = bag_pathname.join("validation-errors.txt")
        errors.open('w') {|file| file.puts invalid_signatures}
        raise "Bag data validation error(s): #{bag_pathname.to_s} - see #{errors.realpath}"
      else
        true
      end
    end

    def verification_queries(druid)
      queries = []
      queries
    end

    def verification_files(druid)
      deposit_bag_pathname = find_deposit_pathname(druid)
      files = []
      files << deposit_bag_pathname.join("bag-info.txt").to_s
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::ValidateBag.new()
  dm_robot.start
end
