require_relative '../libdir'
require 'boot'

module Robots
  module SdrRepo
    module SdrIngest

      # Robot for completing the processing of each ingested object
      class IngestCleanup < SdrRobot

        # class instance variables (accessors defined in SdrRobot parent class)
        @workflow_name = 'sdrIngestWF'
        @step_name = 'ingest-cleanup'

        # set workflow name, step name, log location, log severity level
        def initialize(opts = {})
          super(self.class.workflow_name, self.class.step_name, opts)
        end

        # @param druid [String] The item to be processed
        # @return [void] process an object from the queue through this robot
        #   See LyberCore::Robot#work
        def perform(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
          bag_pathname = Replication::SdrObject.new(druid).deposit_bag_pathname
          ingest_cleanup(druid, bag_pathname)
        end

        # @param druid [String] The object identifier
        # @param bag_pathname [Pathname] The location of the BagIt bag being ingested
        # @return [void] complete ingest of the item, update provenance, cleanup deposit data.
        def ingest_cleanup(druid, bag_pathname)
          cleanup_deposit_files(druid, bag_pathname) if bag_pathname.exist?
          update_workflow_status('dor', druid, 'accessionWF', 'sdr-ingest-received', 'completed', 1)
        end

        # @param druid [String] The object identifier
        # @param bag_pathname [Object] The temp location of the bag containing the object version being deposited
        # @return [Boolean] Cleanup the temp deposit files, raising an error if cleanup failes after 3 attempts
        def cleanup_deposit_files(druid, bag_pathname)
          # retry up to 3 times
          sleep_time = [0, 2, 6]
          attempts ||= 0
          bag_pathname.rmtree
          return true
        rescue Exception => e
          if (attempts += 1) < sleep_time.size
            GC.start
            sleep sleep_time[attempts].to_i
            retry
          else
            raise ItemError.new("Failed cleanup deposit (#{attempts} attempts)")
          end
        end

        def verification_queries(druid)
          workflow_url = Dor::Config.workflow.url
          queries = []
          queries << [
              "#{workflow_url}/sdr/objects/#{druid}/workflows/sdrIngestWF",
              200, /completed/]
          queries
        end

        def verification_files(druid)
          files = []
          files << Moab::StorageServices.object_path(druid).to_s
          files
        end

      end

    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  ARGF.each do |druid|
    dm_robot = Robots::SdrRepo::SdrIngest::IngestCleanup.new()
    dm_robot.process_item(druid)
  end
end
