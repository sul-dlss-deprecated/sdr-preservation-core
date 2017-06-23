#!/usr/bin/env ruby
#
# Class and script to be used for deleting one or more objects from SDR Preservation Core
# One can either pipe a list of druids to the script or specify a filename containing the list on the command line
# syntax examples
#
# echo xg086nq7357 | ~/sdr-preservation-core/current/bin/bundle-exec.sh purge_object.rb
# ~/sdr-preservation-core/current/bin/bundle-exec.sh purge_object.rb  myfile.txt

# Load the deployment environment
require_relative 'environment'

# Make sure this cannot run on the production machine
if ENV['ROBOT_ENVIRONMENT'] == 'production'
  raise 'Not allowed to delete objects on a production environment'
end

class PurgeObject

  # Find the digital object's storage location
  # @param druid [String] The object identifier
  # @return [Moab::StorageObject] The storage object representing the digital object's storage
  def find_storage_object(druid)
    druid = "druid:#{druid}" unless druid.start_with?('druid')
    Moab::StorageServices.find_storage_object(druid)
  end

  # Find the digital object version's storage sub-location (not used at present)
  # @param druid [String] The object identifier
  # @param [Integer] version_id the version identifier
  # @return [Moab::StorageObjectVersion] The storage object version representing the digital object version's storage
  def find_storage_object_version(druid, version_id=nil)
    storage_object = find_storage_object(druid)
    storage_object.find_object_version(version_id)
  end

  # Delete the specified object from preservation core
  # @param druid [String] The object identifier
  # @return [Boolean] true if delete succeeds, false on failure
  def delete_object(druid)
    storage_object = find_storage_object(druid)
    object_pathname = storage_object.object_pathname
    delete_storage(object_pathname)

    # TODO: remove any replicas from the replica-cache.

  end

  # Delete the storage location of the specified object
  # @param object_pathname [Pathname] The storage location of the object being deleted
  # @return [Boolean] true if delete succeeds, false on failure
  def delete_storage(object_pathname)
    # retry up to 3 times
    sleep_time = [0, 2, 6]
    attempts ||= 0
    object_pathname.rmtree if object_pathname.exist?
    puts "deleted #{object_pathname}"
    return true
  rescue Exception => e
    if (attempts += 1) < sleep_time.size
      sleep sleep_time[attempts].to_i
      retry
    else
      puts "unable to delete #{object_pathname} (#{attempts} attempts)"
      return false
    end
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  po = PurgeObject.new
  ARGF.each do |druid|
    begin
      druid.chomp!
      po.delete_object(druid) unless druid.empty?
    rescue
    end
  end
end
