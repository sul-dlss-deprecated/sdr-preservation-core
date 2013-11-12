require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'
require 'sdr_ingest/complete_deposit'

module Sdr

  # A robot for completing the migration of the queued objects
  # Most methods inherit from complete-deposit robot's class
  class MigrationComplete < CompleteDeposit

    @workflow_name = 'sdrMigrationWF'
    @workflow_step = 'migration-complete'

    # @param druid [String] The object identifier
    # @param storage_object [StorageObject] The representation of a digitial object's storage directory
    # @return [void] complete ingest of the item,  cleanup temp deposit data.
    def complete_deposit(druid,storage_object)
      new_version = storage_object.ingest_bag
      result = new_version.verify_version_storage
      if result.verified == false
        LyberCore::Log.info result.to_json(verbose=false)
        raise LyberCore::Exceptions::ItemError.new(druid, "Failed validation",e)
      end
      #update_provenance(druid)
      bag_pathname = storage_object.deposit_bag_pathname
      cleanup_deposit_files(druid, bag_pathname)
    end

    # @param druid [String] The object identifier
    # @param bag_pathname [Object] The temp location of the bag containing the object version being deposited
    # @return [Boolean] Cleanup the temp deposit files, raising an error if cleanup failes after 3 attempts
    def cleanup_deposit_files(druid, bag_pathname)
      # retry up to 3 times
      sleep_time = [0,2,6]
      attempts ||= 0
      bag_pathname.rmtree
      return true
    rescue Exception => e
      if (attempts += 1) < sleep_time.size
        GC.start
        sleep sleep_time[attempts].to_i
        retry
      else
        raise LyberCore::Exceptions::ItemError.new(druid, "Failed cleanup deposit (#{attempts} attempts)", e)
      end
    end

    def verification_queries(druid)
      storage_url = Sdr::Config.sdr_storage_url
      workflow_url = Dor::Config.workflow.url
      queries = []
      queries << [
          "#{storage_url}/objects/#{druid}",
          200, /<html>/ ]
      queries << [
          "#{workflow_url}/sdr/objects/#{druid}/workflows/sdrMigrationWF",
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
  dm_robot = Sdr::MigrationComplete.new()
  dm_robot.start
end