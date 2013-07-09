require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for transferring objects from the DOR export area to the SDR deposit area.
  class TransferObject < SdrRobot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'transfer-object'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
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
    # @return [void] Transfer and untar the object from the DOR export area to the SDR deposit area.
    #   Note: POSIX tar has a limit of 100 chars in a filename
    #     some implementations of gnu TAR work around this by adding a ././@LongLink file containing the full name
    #     See: http://www.delorie.com/gnu/docs/tar/tar_114.html
    #      http://stackoverflow.com/questions/2078778/what-exactly-is-the-gnu-tar-longlink-trick
    #      http://www.gnu.org/software/tar/manual/html_section/Portability.html
    #   Also, beware of incompatabilities between BSD tar and other TAR formats
    #     regarding the handling of vendor extended attributes.
    #     See: http://xorl.wordpress.com/2012/05/15/admin-mistakes-gnu-bsd-tar-and-posix-compatibility/
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

    def verification_queries(druid)
      queries = []
      queries
    end

    def verification_files(druid)
      files = []
        files << Pathname(Sdr::Config.sdr_deposit_home).join(druid.sub('druid:','')).to_s
      files
    end

  end

end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::TransferObject.new()
  dm_robot.start
end



