require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'
require 'bagit'

module Sdr

  # Robot for Validating BagIt bags that are transferred to SDR's deposit area.
  class ValidateBag < LyberCore::Robots::Robot

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
      validate_bag(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [Boolean] Validate the bag containing the digital object
    def validate_bag(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter validate_bag")
      bag_pathname = DepositObject.new(druid).bag_pathname()
      validate_bag_structure(druid, bag_pathname)
      validate_bag_data(druid, bag_pathname)
    end

    # @param druid [String] The object identifier
    # @return [Boolean] Ensure that the bag, expected subdirs, and tag files all exist
    def validate_bag_structure(druid, bag_pathname)

      LyberCore::Log.debug("bag_dir is : #{bag_pathname.to_s}")

      # bag_dir must exist and be a directory
      unless bag_pathname.directory?
        raise LyberCore::Exceptions::ItemError.new(druid, "#{bag_pathname.to_s} does not exist or is not a directory")
      end

      # data_dir must exist and be a directory
      data_dir = bag_pathname.join("data")
      unless data_dir.directory?
        raise LyberCore::Exceptions::ItemError.new(druid, "#{data_dir.to_s} does not exist or is not a directory")
      end

      # The bagit text file must exist and be a file
      bagit_txt_file = bag_pathname.join("bagit.txt")
      unless bagit_txt_file.file?
        raise LyberCore::Exceptions::ItemError.new(druid, "#{bagit_txt_file.to_s} does not exist or is not a file")
      end

      # bag_info_txt_file must exist and be a file
      bag_info_txt_file = bag_pathname.join("bag-info.txt")
      unless bag_info_txt_file.file?
        raise LyberCore::Exceptions::ItemError.new(druid, "#{bag_info_txt_file.to_s} does not exist or is not a file")
      end

     true
    end

    # @param druid [String] The object identifier
    # @return [Boolean] Use the BagIt gem's validation method to verify checksums
    def validate_bag_data(druid, bag_pathname)
      bag = BagIt::Bag.new bag_pathname.to_s
      unless bag.valid?
        raise LyberCore::Exceptions::ItemError.new(druid, "bag not valid: #{bag_pathname.to_s}")
      end
      true
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::ValidateBag.new()
  dm_robot.start
end
