require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for validating storage objects
  class AuditVerify < SdrRobot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrAuditWF'
    @workflow_step = 'audit-verify'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # @return [AuditVerify] set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      audit_verify(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [Boolean] Reconcile manifests against the files in the digital object's storage location
    def audit_verify(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter audit_verify")
      storage_object = StorageServices.storage_object(druid,create=false)
      result = storage_object.verify_object_storage
      if result.verified
        LyberCore::Log.info "Verification Result:\n" + result.to_json(verbose=Sdr::Config.audit_verbose)
      else
        LyberCore::Log.info "Verification Result:\n" + result.to_json(verbose=false)
        raise LyberCore::Exceptions::ItemError.new(druid, "Failed verification",e)
      end
      true
    end

    def verification_queries(druid)
      queries = []
      queries
    end

    def verification_files(druid)
      storage_object = StorageServices.find_storage_object(druid,include_deposit=true)
      files = []
      files << storage_object.deposit_bag_pathname.join("bag-info.txt").to_s
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  audit_robot = Sdr::AuditVerify.new()
  audit_robot.start
end
