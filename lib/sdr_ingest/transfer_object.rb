require_relative '../libdir'
require 'boot'

module Robots
  module SdrRepo
    module SdrIngest

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
          transfer_object(druid)
        end

        # @param druid [String] The object identifier
        # @param deposit_pathname [Pathname] The location of the BagIt bag being ingested
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
          verify_accesssion_status(druid)
          verify_dor_export(druid)
          verify_version_metadata(druid)
          deposit_home = get_deposit_home(druid)
          transfer_cmd = tarpipe_command(druid, deposit_home)
          Replication::OperatingSystem.execute(transfer_cmd)
        rescue Exception => e
          raise ItemError.new("Error transferring object", e)
        end

        # @param druid [String] The object identifier
        # @return [Boolean] query the workflow service to ensure that accession workflow has appropriate state
        def verify_accesssion_status(druid)
          accession_status = get_workflow_status('dor', druid, 'accessionWF', 'sdr-ingest-transfer')
          if accession_status == 'completed'
            true
          else
            raise ItemError.new("accessionWF:sdr-ingest-transfer status is #{accession_status}")
          end
        end

        # @param druid [String] The object identifier
        # @return [Boolean] query the workflow service to ensure that accession workflow has appropriate state
        def verify_dor_export(druid)
          vmpath = File.join(Sdr::Config.ingest_transfer.export_dir, druid.sub('druid:', ''))
          verify_dor_path(vmpath)
        end

        # @param druid [String] The object identifier
        # @return [Boolean] Test existence of versionMetadata file in export.  Return true if found, false if not
        def verify_version_metadata(druid)
          vmpath = File.join(Sdr::Config.ingest_transfer.export_dir,
                             druid.sub('druid:', ''), "/data/metadata/versionMetadata.xml")
          verify_dor_path(vmpath)
        end

        def verify_dor_path(vmpath)
          exists_cmd = "if ssh " + Sdr::Config.ingest_transfer.account +
              " test -e " + vmpath + ";" + " then echo exists; else echo notfound; fi"
          if (Replication::OperatingSystem.execute(exists_cmd).chomp == 'exists')
            true
          else
            raise "#{vmpath} not found"
          end
        end

        def get_deposit_home(druid)
          deposit_pathname = Replication::SdrObject.new(druid).deposit_bag_pathname
          deposit_home = deposit_pathname.parent
          LyberCore::Log.debug("deposit bag_pathname is : #{deposit_pathname}")
          if deposit_pathname.exist?
            cleanup_deposit_files(druid, deposit_pathname)
          else
            deposit_home.mkpath
          end
          deposit_home
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
            raise ItemError.new("Failed cleanup deposit (3 attempts)", e)
          end
        end

        # @see http://en.wikipedia.org/wiki/User:Chdev/tarpipe
        # ssh user@remotehost "tar -cf - srcdir | tar -C destdir -xf -
        # SSH authentication is by ssh public/private key pairs (see .ssh/authorized_keys on export host).
        # Note that symbolic links from /dor/export to /dor/workspace get translated into real files by use of --dereference
        def tarpipe_command(druid, deposit_home)
          'ssh ' + Sdr::Config.ingest_transfer.account +
              ' "tar -C ' + Sdr::Config.ingest_transfer.export_dir +
              ' --dereference -cf - ' + druid.sub('druid:', '') +
              ' " | tar -C ' + deposit_home.to_s +
              ' -xf -'
        end

        def verification_queries(druid)
          queries = []
          queries
        end

        def verification_files(druid)
          deposit_bag_pathname = Replication::SdrObject.new(druid).deposit_bag_pathname
          files = []
          files << deposit_bag_pathname.to_s
          files
        end

      end

    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Robots::SdrRepo::SdrIngest::TransferObject.new()
  dm_robot.start
end



