require File.join(File.dirname(__FILE__),'libdir')
require 'boot'

module Sdr

  # Robot for transferring objects from the DOR export area to the SDR deposit area.
  class TransferObject < LyberCore::Robots::Robot

    # set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super('sdrIngestWF', 'transfer-object', opts)
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      transfer_object(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [void] Transfer the object from the DOR export area to the SDR deposit area.
    def transfer_object(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter transfer_object")
      deposit_object = DepositObject.new(druid)
      bag_pathname = deposit_object.bag_pathname(verify=false)
      tarfile_pathname =deposit_object.tarfile_pathname()
      transfer_bag(druid, bag_pathname, tarfile_pathname)
      untar_bag(druid, bag_pathname, tarfile_pathname)
      cleanup_tarfile(druid, tarfile_pathname)
    end

    # @param druid [String] The object identifier
    # @return [void] Copy the TAR file containing the object using Rsync
    def transfer_bag(druid, bag_pathname, tarfile_pathname)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter transfer_object")
      LyberCore::Log.debug("bag_pathname is : #{bag_pathname}")
      if bag_pathname.exist?
        raise LyberCore::Exceptions::ItemError.new(druid, "Deposit bag already exists at destination: #{bag_pathname.to_s}")
      else
        tarfile = tarfile_pathname.basename.to_s
        LyberCore::Log.debug("Tar file name being transferred is : #{tarfile}")
        begin
          bag_pathname.parent.mkpath
          bag_parent_dir = bag_pathname.parent.to_s
          LyberCore::Utils::FileUtilities.transfer_object(tarfile, Sdr::Config.dor_export, bag_parent_dir)
          LyberCore::Log.debug("#{tarfile} transferred to #{bag_parent_dir}")
        rescue Exception => e
          raise LyberCore::Exceptions::ItemError.new(druid, "Error transferring object", e)
        end
      end
    end

    # @param druid [String] The object identifier
    # @return [void] Unpack the TAR file.
    def untar_bag(druid, bag_pathname, tarfile_pathname)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter untar_bag")
      bag_parent_dir = bag_pathname.parent.to_s
      tarfile = tarfile_pathname.basename.to_s
      unpackcommand = "cd #{bag_parent_dir}; tar xf #{tarfile} --force-local"
      LyberCore::Log.debug("Unpack command is :  #{unpackcommand}")
      status = system(unpackcommand)
      LyberCore::Log.debug("Return from untar is : #{status}")
      if status != true
        raise LyberCore::Exceptions::ItemError.new(druid, "#{unpackcommand} failed")
      end
    end

    # @param druid [String] The object identifier
    # @return [void] Delete the tar file.
    def cleanup_tarfile(druid, tarfile_pathname)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter cleanup_tarfile")
      tarfile_pathname.delete
      tarfile = tarfile_pathname.basename.to_s
      LyberCore::Log.debug("File : #{tarfile} now deleted")
    rescue Exception => e
      raise LyberCore::Exceptions::ItemError.new(druid, "Unable to delete #{tarfile}", e)
    end

  end

end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::TransferObject.new()
  dm_robot.start
end



