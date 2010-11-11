#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'lyber_core/utils'
require 'English'
require 'logger'

module SdrIngest

# +TransferObject+ Transfers objects from DOR workspace to SDR's staging area.
# - notifies DOR of success by: <b><i>need to be filled in</i></b>
# - notifies DOR of missing object by: <i><b>need to be filled in</b></i>

  class TransferObject < LyberCore::Robots::Robot

    # the destination object that gets created by running this script
    attr_reader :dest_path
    attr_reader :env

    # Initialize the robot by calling LyberCore::Robots::Robot.new
    # with the workflow name and the workflow step
    def initialize()
      super('sdrIngestWF', 'transfer-object',
        :logfile => '/tmp/transfer-object.log', 
        :loglevel => Logger::INFO,
        :options => ARGV[0])
        
        # have to be able to change logfile and loglevel from config option or command line

      @env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
    end


    # Override the robot LyberCore::Robot.process_item method.
    # * Makes use of the Robot Framework FileUtilities.
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      # Identifiers
      begin
        druid = work_item.druid
      rescue => e
        # more information needed
        LyberCore::Log.error("Cannot get a druid from the workflow")
        raise e
      end
      @dest_path = File.join(SDR_DEPOSIT_DIR,druid)
      LyberCore::Log.debug("dest_path is : #{@dest_path}")
      if File.exists?(@dest_path)
        puts "Object already exists: #{@dest_path}"
      else
        # filename is druid.tar
        filename = druid + ".tar"
        LyberCore::Log.debug("Tar file name being transferred is : #{filename}")
        begin
          LyberCore::Utils::FileUtilities.transfer_object(filename, DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR)
        rescue   => e
          LyberCore::Log.error("Error in transferring object : #{e.inspect}")
          LyberCore::Log.error("#{e.backtrace.join("\n")}")
          
          # TODO: what do we want to do here ? raise or continue ?
          raise e
        end
        
        LyberCore::Log.debug("#{filename} transferred to #{SDR_DEPOSIT_DIR}")

        # if env = sdr-services-test then untar the file directly in SDR_UNPACK_SERVER(sdr-thumper5)
        # e.g ssh sdr-thumper5 "cd ~/target/sdr2objects; tar xf 4177.tar"
        if (@env == "sdr-services-test")
            unpackcommand = "ssh #{SDR_UNPACK_SERVER}  \"cd #{SDR_UNPACK_DIR}; tar xf #{filename} --force-local\""
        else
            unpackcommand = "cd #{SDR_UNPACK_DIR}; tar xf #{filename} --force-local"
        end
        LyberCore::Log.debug("Unpack command is :  #{unpackcommand}")
        status = system(unpackcommand)
        
        LyberCore::Log.debug("Return from untar is : #{status}")
        if (status != true)
          raise "Cannot execute #{unpackcommand}"
        end

      end
    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  begin
    dm_robot = SdrIngest::TransferObject.new()
    dm_robot.start
  rescue => e
    puts "ERROR : " + e.message
  end
  puts "Transfer Object done\n"
end


