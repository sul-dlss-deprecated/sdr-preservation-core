require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'
require 'sdr_ingest/complete_deposit'

module Sdr

  # A robot for copying the recovered object versions to online storage
  class RecoveryRestore < LyberCore::Robots::Robot

    @workflow_name = 'sdrRecoveryWF'
    @workflow_step = 'recovery-restore'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # @return [RecoveryRestore] set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      recovery_restore(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [void] transfer recovered object files to repository storage.
    def recovery_restore(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter recovery_restore")
      repository = Stanford::StorageRepository.new
      storage_object = repository.storage_object(druid,create=true)
      recovery_path = Pathname(Sdr::Config.sdr_recovery_home).join(druid.sub('druid:',''))
      storage_object.restore_object(recovery_path)
    rescue Exception => e
      raise LyberCore::Exceptions::ItemError.new(druid, "Failed restore",e)
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
      repository = Stanford::StorageRepository.new
      files = []
      files << repository.storage_object_pathname(druid).to_s
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::RecoveryRestore.new()
  dm_robot.start
end