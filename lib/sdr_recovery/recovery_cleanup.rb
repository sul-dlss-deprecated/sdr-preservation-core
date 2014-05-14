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

    # @param druid [String] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   See LyberCore::Robot#work
    def perform(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
      recovery_cleanup(druid)
    end

    # @param druid [String] The object identifier
    # @return [Boolean] complete ingest of the item,  cleanup temp deposit data.
    def recovery_cleanup(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter recovery_cleanup")
      recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(druid.sub('druid:',''))
      cleanup_recovery_files(druid, recovery_path) if recovery_path.exist?
    end

    # @param druid [String] The object identifier
    # @param recovery_path [Pathname] The temp location of the folder containing the object files being restored
    # @return [Boolean] Cleanup the temp recovery files, raising an error if cleanup failes after 3 attempts
    def cleanup_recovery_files(druid, recovery_path)
      # retry up to 3 times
      tries ||= 3
      recovery_path.rmtree
      return true
    rescue Exception => e
      if (tries -= 1) > 0
        GC.start
        retry
      else
        raise Sdr::ItemError.new(druid, "Failed rmtree #{recovery_path} (3 attempts)", e)
      end
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