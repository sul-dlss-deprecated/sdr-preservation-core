require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # A robot for file cleanup after the object recovery 
  class RecoveryCleanup < SdrRobot

    @workflow_name = 'sdrRecoveryWF'
    @workflow_step = 'recovery-cleanup'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # @return [RecoveryCleanup] set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      recovery_cleanup(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [void] complete ingest of the item,  cleanup temp deposit data.
    def recovery_cleanup(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter recovery_cleanup")
      recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(druid.sub('druid:',''))
      recovery_path.rmtree if recovery_path.exist?
    end

    def verification_queries(druid)
      queries = []
      queries
    end

    def verification_files(druid)
      files = []
      files <<  Sdr::Config.sdr_recovery_home
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::RecoveryCleanup.new()
  dm_robot.start
end