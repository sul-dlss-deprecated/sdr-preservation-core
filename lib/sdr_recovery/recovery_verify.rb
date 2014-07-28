require_relative '../libdir'
require 'boot'

module Robots
  module SdrRepo
    module SdrRecovery

      # Robot for validating recovered object versions
      class RecoveryVerify < SdrRobot

        # class instance variables (accessors defined in SdrRobot parent class)
        @workflow_name = 'sdrRecoveryWF'
        @step_name = 'recovery-verify'

        # @return [RecoveryVerify] set workflow name, step name, log location, log severity level
        def initialize(opts = {})
          super(self.class.workflow_name, self.class.step_name, opts)
        end

        # @param druid [String] The item to be processed
        # @return [void] process an object from the queue through this robot
        #   See LyberCore::Robot#work
        def perform(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
          recovery_verify(druid)
        end

        # @param druid [String] The object identifier
        # @return [Boolean] Verify the bag containing the digital object
        def recovery_verify(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter recovery_verify")
          recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(druid.sub('druid:', ''))
          recovery_object = Moab::StorageObject.new(druid, recovery_path)
          result = recovery_object.verify_object_storage
          if result.verified == false
            LyberCore::Log.info result.to_json(verbose=false)
            raise ItemError.new("Failed verification", e)
          end
          true
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
    dm_robot = Robots::SdrRepo::SdrRecovery::RecoveryVerify.new()
    dm_robot.process_item(druid)
  end
end
