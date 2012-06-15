require File.join(File.dirname(__FILE__),'libdir')
require 'boot'

module Sdr

# Transfers objects from DOR workspace to SDR's staging area.
  class TransferObject < LyberCore::Robots::Robot

    def initialize()
    # Initialize the robot by calling LyberCore::Robots::Robot.new
    # with the workflow name and the workflow step
      super('sdrIngestWF', 'transfer-object',
        :logfile => "#{Sdr::Config.logdir}/transfer-object.log",
        :loglevel => Logger::INFO,
        :options => ARGV[0])
      env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{env}")
      LyberCore::Log.debug("Process ID is : #{$$}")
    end

    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      transfer_object(work_item.druid)
    end

    # Transfer the object's bag from the DOR workspace to the SDR storage area
    # Overrides the robot LyberCore::Robot.process_item method.
    def transfer_object(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter transfer_object")
      transfer_bag(druid)
      untar_bag(druid)
      cleanup_tarfile(druid)
    end

    def transfer_bag(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter transfer_object")
      bag_dir = SdrDeposit.bag_pathname(druid)
      LyberCore::Log.debug("object_pathname is : #{bag_dir}")
      if bag_dir.exists?
        raise LyberCore::Exceptions::ItemError.new(druid, "Object already exists at destination: #{bag_dir.to_s}")
      else
        # filename is druid.tar
        filename = druid + ".tar"
        LyberCore::Log.debug("Tar file name being transferred is : #{filename}")
        begin
          bag_parent_dir = bag_dir.parent
          bag_parent_dir.mkpath
          LyberCore::Utils::FileUtilities.transfer_object(filename, Sdr::Config.dor_export, bag_parent_dir.to_s)
          LyberCore::Log.debug("#{filename} transferred to #{bag_parent_dir.to_s}")
        rescue Exception => e
          raise LyberCore::Exceptions::ItemError.new(druid, "Error transferring object", e)
        end
      end
    end


    # Untar the file and delete the tarfile if successful
    def untar_bag(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter untar_bag")
      bag_parent_dir = SdrDeposit.bag_pathname(druid).parent
      filename = druid + ".tar"
      unpackcommand = "cd #{bag_parent_dir.to_s}; tar xf #{filename} --force-local"
      LyberCore::Log.debug("Unpack command is :  #{unpackcommand}")
      status = system(unpackcommand)
      LyberCore::Log.debug("Return from untar is : #{status}")
      if status != true
        raise LyberCore::Exceptions::ItemError.new(druid, "#{unpackcommand} failed")
      end
    end

    # remove the tar file
    def cleanup_tarfile(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter cleanup_tarfile")
      tarfile =SdrDeposit.tarfile_pathname(druid)
      tarfile.delete
      LyberCore::Log.debug("File : #{tarfile.to_s} now deleted")
    rescue Exception => e
      raise LyberCore::Exceptions::ItemError.new(druid, "Unable to delete #{tarfile.to_s}", e)
    end

  end

end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::TransferObject.new()
  dm_robot.start
end



