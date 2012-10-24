require File.join(File.dirname(__FILE__), '../libdir')
require 'boot'

module Sdr

  # Robot for initializing the workflow of each migrated object
  class MigrationStart < LyberCore::Robots::Robot
    @workflow_name = 'sdrMigrationWF'
    @workflow_step = 'migration-start'
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
      create_migration_workflow(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [void] Transfer the object from the DOR export area to the SDR deposit area.
    def create_migration_workflow(druid)
      wf_xml = read_sdr_migration_workflow_xml()
     # Now bootstrap SDR workflow queue to start SDR robots
     # Set the repo as 'sdr', and do not create a workflows datastream in sedora
      Dor::WorkflowService.create_workflow('sdr', druid, 'sdrMigrationWF', wf_xml, opts = {:create_ds => false})
    end

    # Read in the XML file needed to initialize the SDR workflow
    # @return [String]
    def read_sdr_migration_workflow_xml()
      IO.read(File.join("#{ROBOT_ROOT}", "config", "workflows", "sdrMigrationWF", "sdrMigrationWF.xml"))
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::MigrationStart.new()
  dm_robot.start
end