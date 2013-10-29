require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for completing the processing of each ingested object
  class CompleteDeposit < SdrRobot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'complete-deposit'
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
      storage_object = StorageServices.find_storage_object(work_item.druid,include_deposit=true)
      storage_object.object_pathname.mkpath
      complete_deposit(work_item.druid,storage_object)
    end

    # @param druid [String] The object identifier
    # @param storage_object [StorageObject] The representation of a digitial object's storage directory
    # @return [void] complete ingest of the item, update provenance, cleanup deposit data.
    def complete_deposit(druid,storage_object)
      new_version = storage_object.ingest_bag
      result = new_version.verify_version_storage
      if result.verified == false
        LyberCore::Log.info result.to_json(verbose=false)
        raise LyberCore::Exceptions::ItemError.new(druid, "Failed verification")
      end
    end

    def verification_queries(druid)
      storage_url = Sdr::Config.sdr_storage_url
      workflow_url = Dor::Config.workflow.url
      queries = []
      queries << [
          "#{storage_url}/objects/#{druid}",
          200, /<html>/ ]
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
  dm_robot = Sdr::CompleteDeposit.new()
  dm_robot.start
end
