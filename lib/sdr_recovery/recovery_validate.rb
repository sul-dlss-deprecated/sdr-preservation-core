require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for validating recovered object versions
  class RecoveryValidate < LyberCore::Robots::Robot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrRecoveryWF'
    @workflow_step = 'recovery-validate'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # @return [RecoveryValidate] set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      recovery_validate(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [Boolean] Validate the bag containing the digital object
    def recovery_validate(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter recovery_validate")
      recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(druid.sub('druid:',''))
      recovery_object = Moab::StorageObject.new(druid,recovery_path)
      recovery_object.versions.each do |recovery_version|
        recovery_version.verify_manifest_inventory
        recovery_version.verify_version_additions
      end
      true
    rescue Exception => e
      raise LyberCore::Exceptions::ItemError.new(druid, "Failed validation",e)
    end

    def verification_queries(druid)
      queries = []
      queries
    end

    def verification_files(druid)
      bag_pathname = Pathname(Sdr::Config.sdr_deposit_home).join(druid.sub('druid:',''))
      files = []
      files << bag_pathname.join("bag-info.txt").to_s
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::RecoveryValidate.new()
  dm_robot.start
end
