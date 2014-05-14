require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for validating storage objects
  class AuditVerify < SdrRobot

    # class instance variables (accessors defined in SdrRobot parent class)
    @workflow_name = 'sdrAuditWF'
    @step_name = 'audit-verify'

    # @return [AuditVerify] set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.step_name, opts)
    end

    # @param druid [String] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   See LyberCore::Robot#work
    def perform(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
      audit_verify(druid)
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
        raise Sdr::ItemError.new(druid, "Failed verification",e)
      end
      true
    end

    def verification_queries(druid)
      queries = []
      queries
    end

    def verification_files(druid)
      deposit_bag_pathname = find_deposit_pathname(druid)
      files = []
      files << deposit_bag_pathname.join("bag-info.txt").to_s
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  audit_robot = Sdr::AuditVerify.new()
  audit_robot.start
end
