require File.join(File.dirname(__FILE__), 'libdir')
require 'boot'
require 'bagit'

module Sdr

  # Validates the Bag that has been transferring in SDR's staging area
  class ValidateBag < LyberCore::Robots::Robot

    def initialize()
      super('sdrIngestWF', 'validate-bag',
            :logfile => "#{Sdr::Config.logdir}/validate-bag.log",
            :loglevel => Logger::INFO,
            :options => ARGV[0])
      env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{env}")
      LyberCore::Log.debug("Process ID is : #{$$}")
    end

    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      validate_bag(work_item.druid)
    end

    # Validate the bag containing the object's content and metadata
    # Overrides the robot LyberCore::Robot.process_item method.
    def validate_bag(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter validate_bag")
      validate_bag_structure(druid)
      validate_bag_data(druid)
    end

  end # end of class

  # Ensure that the bag exists by checking for the presence of bagit.txt and
  # bag-info.txt
  def validate_bag_structure(druid)

    bag_dir = SdrDeposit.bag_pathname(druid)
    LyberCore::Log.debug("bag_dir is : #{bag_dir.to_s}")

    # bag_dir must exist and be a directory
    unless bag_dir.directory?
      raise LyberCore::Exceptions::ItemError.new(druid, "#{bag_dir.to_s} does not exist or is not a directory")
    end

    # data_dir must exist and be a directory
    data_dir = bag_dir.join("data")
    unless data_dir.directory?
      raise LyberCore::Exceptions::ItemError.new(druid, "#{data_dir.to_s} does not exist or is not a directory")
    end

    # The bagit text file must exist and be a file
    bagit_txt_file = bag_dir.join("bagit.txt")
    unless bagit_txt_file.file?
      raise LyberCore::Exceptions::ItemError.new(druid, "#{bagit_txt_file.to_s} does not exist or is not a file")
    end

    # bag_info_txt_file must exist and be a file
    bag_info_txt_file = bag_dir.join("bag-info.txt")
    unless bag_info_txt_file.file?
      raise LyberCore::Exceptions::ItemError.new(druid, "#{bag_info_txt_file.to_s} does not exist or is not a file")
    end

    ## relationshipMetadata file must contain a valid APO
    #relationship_md_pathname = data_dir.join('metadata/relationshipMetadata.xml')
    #if relationship_md_pathname.exist?
    #  apo_druid = Sdr::VerifyApo.get_apo_druid(relationship_md_pathname)
    #  Sdr::VerifyApo.verify_apo_in_fedora(apo_druid, Sdr::Config.sedora.url)
    #end

    # If all files and directories exist where they should, we assume the bag exists
    true
  end

  def validate_bag_data(druid)
    bag_dir = SdrDeposit.bag_pathname(druid)
    bag = BagIt::Bag.new bag_dir.to_s
    unless bag.valid?
      raise LyberCore::Exceptions::ItemError.new(druid, "bag not valid: #{bag_dir.to_s}")
    end
    true
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::ValidateBag.new()
  dm_robot.start
end
