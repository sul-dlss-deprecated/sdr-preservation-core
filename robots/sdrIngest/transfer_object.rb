#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'lyber_core/utils'
require 'English'
require 'logger'
require 'fileutils'

module SdrIngest

# Transfers objects from DOR workspace to SDR's staging area.
  class TransferObject < LyberCore::Robots::Robot

    # @return [String] The full path of the bag containing the object being processed
    attr_reader :dest_path

    # @return [String] The environment in which the robot is running, e.g. test
    attr_reader :env

    def initialize()
    # Initialize the robot by calling LyberCore::Robots::Robot.new
    # with the workflow name and the workflow step
      super('sdrIngestWF', 'transfer-object',
        :logfile => "#{LOGDIR}/transfer-object.log", 
        :loglevel => Logger::INFO,
        :options => ARGV[0])
      @env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
    end

    # Transfer the object's bag from the DOR workspace to the SDR storage area
    # Overrides the robot LyberCore::Robot.process_item method.
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      druid = work_item.druid
      bag_parent_dir = SdrDeposit.local_bag_parent_dir(druid)
      @dest_path = File.join(bag_parent_dir,druid)
      LyberCore::Log.debug("dest_path is : #{@dest_path}")
      if File.exists?(@dest_path)
        raise LyberCore::Exceptions::ItemError.new(druid, "Bag already exists at destination: #{@dest_path}")
      else
        # filename is druid.tar
        filename = druid + ".tar"
        LyberCore::Log.debug("Tar file name being transferred is : #{filename}")
        begin
          FileUtils.mkdir_p bag_parent_dir
          LyberCore::Utils::FileUtilities.transfer_object(filename, DOR_WORKSPACE_DIR, bag_parent_dir)
        rescue Exception => e
          raise LyberCore::Exceptions::ItemError.new(druid, "Error transferring object", e)
        end
        
        LyberCore::Log.debug("#{filename} transferred to #{bag_parent_dir}")

        # Untar the file and delete the tarfile if successful
        if (@env == "sdr-services-test" || @env == "sdr-services")
            unpack_dir = SdrDeposit.remote_bag_parent_dir(druid)
            unpackcommand = "ssh #{SDR_UNPACK_SERVER}  \"cd #{unpack_dir}; tar xf #{filename}\""
        else
            unpackcommand = "cd #{bag_parent_dir}; tar xf #{filename} --force-local"
        end
        LyberCore::Log.debug("Unpack command is :  #{unpackcommand}")
        status = system(unpackcommand)
        LyberCore::Log.debug("Return from untar is : #{status}")
        if (status == true)
          # remove the tar file
          file = File.join(bag_parent_dir, filename)
          LyberCore::Log.debug("File to be deleted is : #{file} ")
          numfiles = File.delete(file)
          if (numfiles >= 1)
            LyberCore::Log.debug("File : #{filename} now deleted")
          else
            raise LyberCore::Exceptions::ItemError.new(druid, "There was an error deleting #{filename}")
          end
        else
          raise LyberCore::Exceptions::ItemError.new(druid, "#{unpackcommand} failed")
        end

      end
    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::TransferObject.new()
  dm_robot.start
end



