require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for transferring objects from the DOR export area to the SDR deposit area.
  class TransferObject < SdrRobot

    # class instance variables (accessors defined in SdrRobot parent class)
    @workflow_name = 'sdrIngestWF'
    @step_name = 'transfer-object'

    # set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.step_name, opts)
    end

    # @param druid [String] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   See LyberCore::Robot#work
    def perform(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
      bag_pathname = find_deposit_pathname(druid)
      transfer_object(druid,bag_pathname)
    end

    # @param druid [String] The object identifier
    # @param bag_pathname [Pathname] The location of the BagIt bag being ingested
    # @return [void] Transfer and untar the object from the DOR export area to the SDR deposit area.
    #   Note: POSIX tar has a limit of 100 chars in a filename
    #     some implementations of gnu TAR work around this by adding a ././@LongLink file containing the full name
    #     See: http://www.delorie.com/gnu/docs/tar/tar_114.html
    #      http://stackoverflow.com/questions/2078778/what-exactly-is-the-gnu-tar-longlink-trick
    #      http://www.gnu.org/software/tar/manual/html_section/Portability.html
    #   Also, beware of incompatabilities between BSD tar and other TAR formats
    #     regarding the handling of vendor extended attributes.
    #     See: http://xorl.wordpress.com/2012/05/15/admin-mistakes-gnu-bsd-tar-and-posix-compatibility/
    def transfer_object(druid, bag_pathname)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter transfer_object")
      deposit_home = bag_pathname.parent
      deposit_home.mkpath
      LyberCore::Log.debug("deposit bag_pathname is : #{bag_pathname}")
      cleanup_deposit_files(druid, bag_pathname) if bag_pathname.exist?
      raise "versionMetadata.xml not found in export" unless verify_version_metadata(druid)
      shell_execute(tarpipe_command(druid,deposit_home))
      rescue Exception => e
        raise Sdr::ItemError.new(druid, "Error transferring object", e)
    end

    # @param druid [String] The object identifier
    # @param bag_pathname [Object] The temp location of the bag containing the object version being deposited
    # @return [Boolean] Cleanup the temp deposit files, raising an error if cleanup failes after 3 attempts
    def cleanup_deposit_files(druid, bag_pathname)
      # retry up to 3 times
      tries ||= 3
      bag_pathname.rmtree
      return true
    rescue Exception => e
      if (tries -= 1) > 0
        GC.start
        retry
      else
        raise Sdr::ItemError.new(druid, "Failed cleanup deposit (3 attempts)", e)
      end
    end

    # @param druid [String] The object identifier
    # @return [Boolean] Test existence of versionMetadata file in export.  Return true if found, false if not
    def verify_version_metadata(druid)
      vmpath = File.join(Sdr::Config.ingest_transfer.export_dir,
               druid.sub('druid:',''),"/data/metadata/versionMetadata.xml")
      exists_cmd = "if ssh " + Sdr::Config.ingest_transfer.account +
        " test -e " + vmpath + ";" +
        " then echo exists; else echo notfound; fi"
      (shell_execute(exists_cmd).chomp == 'exists')
    end

    # @see http://en.wikipedia.org/wiki/User:Chdev/tarpipe
    # ssh user@remotehost "tar -cf - srcdir | tar -C destdir -xf -
    def tarpipe_command(druid, deposit_home)
      'ssh ' + Sdr::Config.ingest_transfer.account +
      ' "tar -C ' + Sdr::Config.ingest_transfer.export_dir  +
      ' --dereference -cf - ' + druid.sub('druid:','') +
      ' " | tar -C ' + deposit_home.to_s +
      ' -xf -'
    end

    def verification_queries(druid)
      queries = []
      queries
    end

    def verification_files(druid)
      deposit_bag_pathname = find_deposit_pathname(druid)
      files = []
        files << deposit_bag_pathname.to_s
      files
    end

  end

end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::TransferObject.new()
  dm_robot.start
end



