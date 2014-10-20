require_relative '../libdir'
require 'boot'

module Robots
  module SdrRepo
    module SdrIngest

      # A robot for creating new entries in the Archive Catalog for the object version
      class CreateReplica < SdrRobot

        # class instance variables (accessors defined in SdrRobot parent class)
        @workflow_name = 'sdrIngestWF'
        @step_name = 'create-replica'

        # set workflow name, step name, log location, log severity level
        def initialize(opts = {})
          super(self.class.workflow_name, self.class.step_name, opts)
        end

        # @param druid [String] The item to be processed
        # @return [void] process an object from the queue through this robot
        #   See LyberCore::Robot#work
        def perform(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
          create_replica(druid)
        end

        # @param druid [String] The item to be processed
        # @return [void] Craeate a replica bag for the new object version in the replica cache
        #   and update the Archive Catalog's replica table
        def create_replica(druid)
          sdr_object = Replication::SdrObject.new(druid)
          latest_version_id = sdr_object.current_version_id
          sdr_object_version = Replication::SdrObjectVersion.new(sdr_object,latest_version_id)
          @replica = sdr_object_version.create_replica # can raise ReplicaExistsError
          @replica.get_bag_data
          @replica.catalog_replica_data
          # TODO: replicate to tape
          #replicate_to_tape
          # TODO: replicate to dpn
          #replicate_to_dpn
        end

        def replicate_to_tape
          # TODO: push replica to tape?
          # https://consul.stanford.edu/display/SDRnew/SDR+Replication%2C+TSM+Integration
          # Use @replica.bag_pathname
          #dsmc archive
          #http://pic.dhe.ibm.com/infocenter/tsminfo/v6r2/index.jsp?topic=%2Fcom.ibm.itsm.client.doc%2Fc_arc_cmdlinewin.html
          # archive name:
          # 'google spanish collection at /gfetch/languages/spanish/'
          #
          # The data is mostly in the downloads at:
          # ls /gfetch/languages/spanish/download_ouput/
          #
          # The TSM archive session is something like the following:
          #
          # mkdir ~/tsm
          # touch ~/tsm/dsm_error.log  # use a log file with r/w access for gfetch user
          # dsmc -errorlogname=~/tsm/dsm_error.log
          # tsm> ar /home/gfetch/rnanders/* -subdir=yes -desc="Richard Anderson gfetch files in /home/gfetch/rnanders"
        end

        def replicate_to_dpn
          # TODO: create replica in a DPN cache?
          # https://consul.stanford.edu/display/SDRnew/SDR+Replication%2C+DPN+Integration
          # SDR-PC will run a DPN daemon process to handle async messaging
          # it will be able to push out to DPN one replica at a time, it will wait
          # for replication confirmation from DPN.  So it will queue and manage a queue.
          # It might be easiest to wrap the DPN gem in something that will monitor the
          # DPN-cache file system for new content and manage the push and cleanup.  The
          # DPN-cache location and the DPN-rsync deposit location will be config settings,
          # and the fixity algorithm will be a config setting.
          #
          # rsync -av ./{druid}_{ver}.tar lyberadmin@dpn-demo:/dpn_data/staging/
          # message DPN with:
          #    - druid-id, moab-version, file-name, fixity as sha256 on tar file
          # async DPN response:
          #    - druid-id, moab-version, file-name, fixity, dpn-id
        end

        def verification_queries(druid)
          queries = []
          queries
        end

        def verification_files(druid)
          files = []
          files
        end

      end

    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  ARGF.each do |druid|
    dm_robot = Robots::SdrRepo::SdrIngest::CreateReplica.new()
    dm_robot.process_item(druid)
  end
end
