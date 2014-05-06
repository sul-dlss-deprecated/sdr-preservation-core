require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for completing the processing of each ingested object
  class IngestCleanup < SdrRobot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'ingest-cleanup'
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
      bag_pathname = find_deposit_pathname(work_item.druid)
      ingest_cleanup(work_item.druid,bag_pathname )
    end

    # @param druid [String] The object identifier
    # @param bag_pathname [Pathname] The location of the BagIt bag being ingested
    # @return [void] complete ingest of the item, update provenance, cleanup deposit data.
    def ingest_cleanup(druid,bag_pathname )
      cleanup_deposit_files(druid, bag_pathname) if bag_pathname.exist?
      update_workflow_status('dor', druid, 'accessionWF', 'sdr-ingest-received', 'completed')
    end

    # @param druid [String] The object identifier
    # @param bag_pathname [Object] The temp location of the bag containing the object version being deposited
    # @return [Boolean] Cleanup the temp deposit files, raising an error if cleanup failes after 3 attempts
    def cleanup_deposit_files(druid, bag_pathname)
      # retry up to 3 times
      sleep_time = [0,2,6]
      attempts ||= 0
      bag_pathname.rmtree
      return true
    rescue Exception => e
      if (attempts += 1) < sleep_time.size
        GC.start
        sleep sleep_time[attempts].to_i
        retry
      else
        raise LyberCore::Exceptions::ItemError.new(druid, "Failed cleanup deposit (#{attempts} attempts)", e)
      end
    end

    def verification_queries(druid)
      workflow_url = Dor::Config.workflow.url
      queries = []
      queries << [
          "#{workflow_url}/sdr/objects/#{druid}/workflows/sdrIngestWF",
          200, /completed/ ]
      queries
    end

    def verification_files(druid)
      files = []
      files << StorageServices.object_path(druid).to_s
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::IngestCleanup.new()
  dm_robot.start
end
