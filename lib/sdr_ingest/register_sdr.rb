require_relative '../libdir'
require 'boot'

module Sdr

  # A robot for creating +Sedora+ objects and workflow datastreams unless they exist
  class RegisterSdr < SdrRobot

    # class instance variables (accessors defined in SdrRobot parent class)
    @workflow_name = 'sdrIngestWF'
    @step_name = 'register-sdr'

    # set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.step_name, opts)
    end

    # @param druid [String] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   See LyberCore::Robot#work
    def perform(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
      druid=druid
      accession_status = get_workflow_status('dor', druid, 'accessionWF', 'sdr-ingest-transfer')
      unless accession_status == 'completed'
        raise Sdr::ItemError.new(druid, "accessionWF:sdr-ingest-transfer status is #{accession_status}")
      end
      # Create a step (table row) in the current workflow instance for ingest-cleanup robot
      update_workflow_status('sdr',druid, 'sdrIngestWF', 'ingest-cleanup', 'waiting', 0) if @workflow_name == 'sdrIngestWF'
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
