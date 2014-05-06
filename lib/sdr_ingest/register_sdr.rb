require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # A robot for creating +Sedora+ objects and workflow datastreams unless they exist
  class RegisterSdr < SdrRobot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'register-sdr'
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
      druid=work_item.druid
      accession_status = get_workflow_status('dor', druid, 'accessionWF', 'sdr-ingest-transfer')
      unless accession_status == 'completed'
        raise LyberCore::Exceptions::ItemError.new(
                  druid, "accessionWF:sdr-ingest-transfer status is #{accession_status}")
      end
      # Create a step (table row) in the current workflow instance for ingest-cleanup robot
      update_workflow_status('sdr',druid, 'sdrIngestWF', 'ingest-cleanup', 'waiting') if @workflow_name == 'sdrIngestWF'
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

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::RegisterSdr.new()
  dm_robot.start
end
