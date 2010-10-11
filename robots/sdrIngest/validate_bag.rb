#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'bagit'
require 'logger'

DATA_DIR = "data"
BAGIT_TXT = "bagit.txt"
BAG_INFO_TXT = "bag-info.txt" 

module SdrIngest

  # Validates the Bag that has been transferring in SDR's staging area
  class ValidateBag < LyberCore::Robots::Robot

    def initialize(string1,string2)
       super(string1,string2)

       @logg = Logger.new("validate_bag.log")
       @logg.level = Logger::DEBUG
       @logg.formatter = proc{|s,t,p,m|"%5s [%s] (%s) %s :: %s\n" % [s, 
                           t.strftime("%Y-%m-%d %H:%M:%S"), $$, p, m]}
    end
      
      
    # Ensure the bag exists by checking for the presence of bagit.txt and 
    # bag-info.txt
    def bag_exists?(base_path)
    	data_dir = File.join(base_path, DATA_DIR)
    	@logg.debug("data dir is : #{data_dir}")
    	
    	bagit_txt_file = File.join(base_path, BAGIT_TXT)
    	bag_info_txt_file = File.join(base_path, BAG_INFO_TXT)

      # base_path must exist and be a directory
      unless File.directory?(base_path)
        puts "#{base_path} does not exist or is not a directory"
        return false 
      end
      
      # data_dir must exist and be a directory 
      unless File.directory?(data_dir)
        puts "#{data_dir} does not exist or is not a directory"
        return false 
      end
      
      # The bagit text file must exist and be a file
      unless File.file?(bagit_txt_file)
        puts "#{bagit_txt_file} does not exist or is not a file"
        return false 
      end
      
      # bag_info_txt_file must exist and be a file
      unless File.file?(bag_info_txt_file)
        puts "#{bag_info_txt_file} does not exist or is not a file"
        return false 
      end
      
      # If all files and directories exist where they should, we assume the bag exists
      return true
    end
    
    # Allow us to pass in a specific druid instead of requiring a work_item
    # This makes testing from the command line easier, as you can validate
    # a specific item instead of relying on the work queue 
    def process_druid(druid)
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

    # Override the robot LyberCore::Robot.process_item method.
    # Extract the druid and pass it along to process_druid
    # This allows the robot to accept either a work_item or a druid
    def process_item(work_item)
      druid = work_item.druid
      process_druid(druid)
    end
  
  end # end of class

end # end of module 


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::ValidateBag.new('sdrIngestWF', 'validate-bag')
  # If this robot is invoked with a specific druid, it will run for that druid only
  if(ARGV[0])
    puts "Validating bagit object for #{ARGV[0]}"
    dm_robot.process_druid(ARGV[0])
  else
    dm_robot.start
  end
  puts "Done."
end
