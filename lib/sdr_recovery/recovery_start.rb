require File.join(File.dirname(__FILE__), '../libdir')
require 'boot'

module Sdr

  # Robot for initializing the workflow of each migrated object
  class RecoveryStart < SdrRobot
    @workflow_name = 'sdrRecoveryWF'
    @workflow_step = 'recovery-start'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # @return [RecoveryStart] set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
    end

    # @param druid [String] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   See LyberCore::Robot#work
    def perform(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
      create_recovery_workflow(druid)
    end

    # @param druid [String] The object identifier
    # @return [void] Transfer the object from the DOR export area to the SDR deposit area.
    def create_recovery_workflow(druid)
      wf_xml = read_sdr_recovery_workflow_xml()
      # Now bootstrap SDR workflow queue to start SDR robots
      # Set the repo as 'sdr', and do not create a workflows datastream in sedora
      create_workflow_rows('sdr', druid, 'sdrRecoveryWF', wf_xml, opts = {:create_ds => false})
    end

    # Read in the XML file needed to initialize the SDR workflow
    # @return [String]
    def read_sdr_recovery_workflow_xml()
      IO.read(File.join("#{ROBOT_ROOT}", "config", "workflows", "sdrRecoveryWF", "sdrRecoveryWF.xml"))
    end

    def verification_queries(druid)
      workflow_url = Dor::Config.workflow.url
      queries = []
      queries << [
        "#{workflow_url}/sdr/objects/#{druid}/workflows/sdrRecoveryWF",
        200, /completed/ ]
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
  dm_robot = Sdr::RecoveryStart.new()
  dm_robot.start
end