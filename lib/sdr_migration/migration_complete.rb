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
    # @return [void] complete ingest of the item,  cleanup temp deposit data.
    def complete_deposit(druid)
      bag_pathname = DepositObject.new(druid).bag_pathname()
      repository = Stanford::StorageRepository.new
      new_version = repository.store_new_object_version(druid, bag_pathname)
      new_version.verify_storage
      #update_provenance(druid)
      bag_pathname.rmtree
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::MigrationComplete.new()
  dm_robot.start
end