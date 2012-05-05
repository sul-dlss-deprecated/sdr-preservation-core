#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'bagit'
require 'logger'
require 'English'
require 'pathname'

DATA_DIR = "data"
BAGIT_TXT = "bagit.txt"
BAG_INFO_TXT = "bag-info.txt" 

module SdrIngest

  # Validates the Bag that has been transferring in SDR's staging area
  class ValidateBag < LyberCore::Robots::Robot

    def initialize()
        super('sdrIngestWF', 'validate-bag',
          :logfile => "#{LOGDIR}/validate-bag.log", 
          :loglevel => Logger::INFO,
          :options => ARGV[0])
        @env = ENV['ROBOT_ENVIRONMENT']
        LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
        LyberCore::Log.debug("Process ID is : #{$PID}")
     end
      
      
    # Ensure that the bag exists by checking for the presence of bagit.txt and
    # bag-info.txt
    def bag_exists?(druid, base_path)
    	data_dir = File.join(base_path, DATA_DIR)
    	LyberCore::Log.debug("data dir is : #{data_dir}")
    	
    	bagit_txt_file = File.join(base_path, BAGIT_TXT)
    	bag_info_txt_file = File.join(base_path, BAG_INFO_TXT)

      # base_path must exist and be a directory
      unless File.directory?(base_path)
        raise LyberCore::Exceptions::ItemError.new(druid,"#{base_path} does not exist or is not a directory")
      end
      
      # data_dir must exist and be a directory 
      unless File.directory?(data_dir)
        raise LyberCore::Exceptions::ItemError.new(druid,"#{data_dir} does not exist or is not a directory")
      end
      
      # The bagit text file must exist and be a file
      unless File.file?(bagit_txt_file)
        raise LyberCore::Exceptions::ItemError.new(druid,"#{bagit_txt_file} does not exist or is not a file")
      end
      
      # bag_info_txt_file must exist and be a file
      unless File.file?(bag_info_txt_file)
        raise LyberCore::Exceptions::ItemError.new(druid,"#{bag_info_txt_file} does not exist or is not a file")
      end

      # relationshipMetadata file must contain a valid APO
      relationship_md_pathname = Pathname.new(data_dir).join('metadata/relationshipMetadata.xml')
      if relationship_md_pathname.exist?
        apo_druid = SdrIngest::VerifyApo.get_apo_druid(relationship_md_pathname)
        SdrIngest::VerifyApo.verify_apo_in_fedora(apo_druid, SEDORA_URI)
      end

      # If all files and directories exist where they should, we assume the bag exists
      return true
    end

    # Validate the bag containing the object's content and metadata
    # Overrides the robot LyberCore::Robot.process_item method.
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      druid = work_item.druid
      dest_path = SdrDeposit.local_bag_path(druid)
      LyberCore::Log.debug("dest_path is : #{dest_path}")
      if bag_exists?(druid, dest_path)
        bag = BagIt::Bag.new dest_path
     	  if not bag.valid?
          raise LyberCore::Exceptions::ItemError.new(druid, "bag not valid: #{dest_path}")
         end
      end
    end
  
  end # end of class

end # end of module

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::ValidateBag.new()
  dm_robot.start
end
