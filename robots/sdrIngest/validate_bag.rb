#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'bagit'

module SdrIngest

  # Validates the Bag that has been transferring in SDR's staging area
  class ValidateBag < LyberCore::Robot

    def bag_exists?(base_path)
    	data_dir = File.join(base_path, "data")
	bagit_txt_file = File.join(base_path, "bagit.txt")
	package_info_txt_file = File.join(base_path, "package-info.txt")

    	if not (File.exists?(base_path) || File.directory?(base_path) ||
	        File.exists?(data_dir) || File.directory?(data_dir) ||
    		File.exists?(bagit_txt_file) || File.file?(bagit_txt_file) ||
		File.exists?(package_info_txt_file) || File.file?(package_info_txt_file))
	   return false
	else
	   return true # 
	end
    end

    # Override the robot LyberCore::Robot.process_item method.
    # * Makes use of the Robot Framework FileUtilities.
    def process_item(work_item)
      # Identifiers

      druid = work_item.druid
      dest_path = File.join(SDR_DEPOSIT_DIR,druid)
      
      if not bag_exists?(dest_path) 
        raise "bag does not exist at: #{dest_path}"
      else
        bag = BagIt::Bag.new dest_path
     	if not bag.valid?
          raise "bag not valid: #{dest_path}"
        end
      end
      
      return nil

    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::ValidateBag.new(
          'sdrIngest', 'validate-bag')
  dm_robot.start
end
