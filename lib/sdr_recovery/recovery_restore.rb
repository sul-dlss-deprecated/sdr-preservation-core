require_relative '../libdir'
require 'boot'
require 'sdr_ingest/complete_deposit'

module Sdr

  # A robot for copying the recovered object versions to online storage
  class RecoveryRestore < SdrRobot

    # class instance variables (accessors defined in SdrRobot parent class)
    @workflow_name = 'sdrRecoveryWF'
    @step_name = 'recovery-restore'

    # @return [RecoveryRestore] set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.step_name, opts)
    end

    # @param druid [String] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   See LyberCore::Robot#work
    def perform(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
      recovery_restore(druid)
    end

    # @param druid [String] The object identifier
    # @return [void] transfer recovered object files to repository storage.
    def recovery_restore(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter recovery_restore")
      storage_object = StorageServices.storage_object(druid,create=true)
      recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(druid.sub('druid:',''))
      storage_object.restore_object(recovery_path)
      result = storage_object.verify_object_storage
      if result.verified == false
        LyberCore::Log.info result.to_json(verbose=false)
        raise Sdr::ItemError.new(druid, "Failed validation",e)
      end
    rescue Exception => e
      raise Sdr::ItemError.new(druid, "Failed restore",e)
    end

    def verification_queries(druid)
      storage_url = Sdr::Config.sdr_storage_url
      workflow_url = Dor::Config.workflow.url
      queries = []
      queries << [
          "#{storage_url}/objects/#{druid}",
          200, /<html>/ ]
      queries << [
          "#{workflow_url}/sdr/objects/#{druid}/workflows/sdrRecoveryWF",
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
  dm_robot = Sdr::RecoveryRestore.new()
  dm_robot.start
end