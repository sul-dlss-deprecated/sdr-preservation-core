#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'bagit'
require 'logger'
require 'English'

DATA_DIR = "data"
BAGIT_TXT = "bagit.txt"
BAG_INFO_TXT = "bag-info.txt" 

module SdrIngest

  # Validates the Bag that has been transferring in SDR's staging area
  class ValidateBag < LyberCore::Robots::Robot

    def initialize()
        super('sdrIngestWF', 'validate-bag',
          :logfile => '/tmp/validate-bag.log', 
          :loglevel => Logger::DEBUG,
          :options => ARGV[0])

        @env = ENV['ROBOT_ENVIRONMENT']
        LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
        LyberCore::Log.debug("Process ID is : #{$PID}")
        
        # TODO : check if DR_URI or WORKFLOW_URI is set
    
    end
      
      
    # Ensure the bag exists by checking for the presence of bagit.txt and 
    # bag-info.txt
    def bag_exists?(base_path)
    	data_dir = File.join(base_path, DATA_DIR)
    	LyberCore::Log.debug("data dir is : #{data_dir}")
    	
    	bagit_txt_file = File.join(base_path, BAGIT_TXT)
    	bag_info_txt_file = File.join(base_path, BAG_INFO_TXT)

      # base_path must exist and be a directory
      unless File.directory?(base_path)
        LyberCore::Log.error("#{base_path} does not exist or is not a directory")
        return false 
      end
      
      # data_dir must exist and be a directory 
      unless File.directory?(data_dir)
        LyberCore::Log.error("#{data_dir} does not exist or is not a directory")
        return false 
      end
      
      # The bagit text file must exist and be a file
      unless File.file?(bagit_txt_file)
        LyberCore::Log.error("#{bagit_txt_file} does not exist or is not a file")
        return false 
      end
      
      # bag_info_txt_file must exist and be a file
      unless File.file?(bag_info_txt_file)
        LyberCore::Log.error("#{bag_info_txt_file} does not exist or is not a file")
        return false 
      end
      
      # If all files and directories exist where they should, we assume the bag exists
      return true
    end
    
    # Allow us to pass in a specific druid instead of requiring a work_item
    # This makes testing from the command line easier, as you can validate
    # a specific item instead of relying on the work queue 
    def process_druid(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_druid")
      dest_path = File.join(SDR_DEPOSIT_DIR,druid)
      LyberCore::Log.debug("dest_path is : #{dest_path}")
      
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

    # Override the robot LyberCore::Robot.process_item method.
    # Extract the druid and pass it along to process_druid
    # This allows the robot to accept either a work_item or a druid
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      begin
        druid = work_item.druid
        process_druid(druid)
      rescue Exception => e
        LyberCore::Log.error("Error processing  #{druid} : #{e.message} ")
        LyberCore::Log.error("#{e.backtrace.join("\n")}")
        raise e
      end
    end
  
  end # end of class

end # end of module 


# This is the equivalent of a java main method
if __FILE__ == $0
  begin
    dm_robot = SdrIngest::ValidateBag.new()
    # If this robot is invoked with a specific druid, it will run for that druid only
    if(ARGV[0])
      puts "Validating bagit object for #{ARGV[0]}"
      dm_robot.process_druid(ARGV[0])
    else
      dm_robot.start
    end
  rescue Exception => e
    LyberCore::Log.error("#{e.inspect} + #{e.backtrace.join("\n")}")
    puts "ERROR : " + e.message
  end
  puts "Validate Bag Done\n"
end
