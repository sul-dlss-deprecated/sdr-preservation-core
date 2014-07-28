require_relative '../libdir'
require 'boot'
require 'sdr_ingest/transfer_object'

module Robots
  module SdrRepo
    module SdrMigration

      # A robot for copying SDR objects from original storage location to new workspace
      # Rsync is used, which eliminates need for an extra post-transfer validation step
      # http://serverfault.com/questions/217446/reliable-file-copy-move-process-mostly-unix-linux
      # bagit checksum manifests will be used to check fixity in migration-complete setp
      class MigrationTransfer < SdrIngest::TransferObject

        # class instance variables (accessors defined in SdrRobot parent class)
        @workflow_name = 'sdrMigrationWF'
        @step_name = 'migration-transfer'

        # @param druid [String] The object identifier
        # @param deposit_bag_pathname [Pathname] The location of the BagIt bag being ingested
        # @return [void] Transfer the object from the DOR export area to the SDR deposit area.
        def transfer_object(druid, deposit_bag_pathname)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter transfer_object")
          original_bag_pathname = locate_old_bag(druid)
          rsync_object(original_bag_pathname, deposit_bag_pathname)
          remediate_version_metadata(druid, deposit_bag_pathname)
          generate_inventory_manifests(druid, deposit_bag_pathname)
        end


        # @param druid [String] The object identifier
        # @return [Pathname] Find the original ingest location of the specified object
        def locate_old_bag(druid)
          old_storage_area = Pathname(Sdr::Config.migration_source)
          tree_based_pathname = tree_based_location(druid, old_storage_area)
          return tree_based_pathname if tree_based_pathname && tree_based_pathname.exist?
          date_based_pathname = date_based_location(druid, old_storage_area)
          return date_based_pathname if date_based_pathname.exist?
          raise ItemError.new("No bag found for druid #{druid}")
        end

        # @param druid [String] The object identifier
        # @param old_storage_area [Pathname] The root directory of the storage location previously used for ingest
        # @return [Pathname] Construct a druid tree path for the specified object based on the old storage area
        def tree_based_location(druid, old_storage_area)
          if druid =~ /^(druid):([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
            old_storage_area.join($1, $2, $3, $4, $5, druid)
          else
            nil
          end
        end

        # @param druid [String] The object identifier
        # @param old_storage_area [Pathname] The root directory of the storage location previously used for ingest
        # @return [Pathname] Construct a druid tree path for the specified object based on the old storage area
        def date_based_location(druid, old_storage_area)
          unless defined? @toc_hash
            # read table of contents file listing date-based paths all older objects
            @toc_hash = Hash.new
            toc_file = old_storage_area.join('deposit-complete.toc')
            toc_file.each_line do |line|
              line.chomp!
              @toc_hash[File.basename(line)] = line
            end
          end
          object_path = @toc_hash[druid]
          return old_storage_area.join(object_path) if object_path
          raise ItemError.new("No line found in deposit-complete.toc for druid #{druid}")
        end

        # @param source_pathname [Pathname] The object's original ingest location
        # @param target_pathname [Pathname] The workspace location to which the object will be copied
        # @return [void] Use rsync to copy the object from original location to workspace location
        def rsync_object(source_pathname, target_pathname)
          # for options see http://rsync.samba.org/ftp/rsync/rsync.html
          # and http://www.rsync.net/resources/howto/mac_images.html
          # trailing slash on the source path means "copy the contents of the source dir to the target dir"
          rsync_command = "rsync -qac --inplace #{source_pathname}/ #{target_pathname}/"
          Replication::OperatingSystem.execute(rsync_command)
          LyberCore::Log.debug("#{source_pathname} transferred to #{target_pathname}")
        rescue Exception => e
          raise ItemError.new("Error transferring object", e)
        end

        # @param druid [String] The object identifier
        # @param bag_pathname [Pathname] The location of the BagIt bag being ingested
        # @return [void] Add a v1 versionMetadata datastream unless it already exists
        def remediate_version_metadata(druid, bag_pathname)
          vm_pathname = bag_pathname.join('data/metadata', "versionMetadata.xml")
          unless vm_pathname.exist?
            template_pathname = Pathname("#{ROBOT_ROOT}/config/versionMetadata-template.xml")
            vm_pathname.open('w') do |vm|
              vm << template_pathname.read.sub(/druid/, druid)
            end
          end
        end

        def generate_inventory_manifests(druid, deposit_bag_pathname)
          version_inventory = get_version_inventory(druid, deposit_bag_pathname)
          version_inventory.write_xml_file(deposit_bag_pathname)
          version_additions = get_version_additions(druid, version_inventory)
          version_additions.write_xml_file(deposit_bag_pathname)
        end

        def get_version_inventory(druid, deposit_bag_pathname)
          version_inventory = FileInventory.new(:type => "version", :digital_object_id => druid, :version_id => 1)
          content_group = get_data_group(deposit_bag_pathname, 'content')
          version_inventory.groups << content_group
          upgrade_content_metadata(deposit_bag_pathname, content_group)
          metadata_group = get_data_group(deposit_bag_pathname, 'metadata')
          version_inventory.groups << metadata_group
          version_inventory
        end

        def get_data_group(deposit_bag_pathname, group_id)
          data_pathname = deposit_bag_pathname.join('data', group_id)
          data_group = Moab::FileGroup.new(:group_id => group_id)
          data_group.group_from_directory(data_pathname)
        end

        def upgrade_content_metadata(deposit_bag_pathname, content_group)
          content_metadata_pathname = deposit_bag_pathname.join('data/metadata/contentMetadata.xml')
          original_cm = content_metadata_pathname.read
          remediator = Stanford::ContentInventory.new
          remediated_cm = remediator.remediate_content_metadata(original_cm, content_group)
          write_content_metadata(remediated_cm, content_metadata_pathname)
          remediated_cm
        end

        def write_content_metadata(remediated_cm, content_metadata_pathname)
          content_metadata_pathname.open('w') { |f| f << remediated_cm }
        end

        def get_version_additions(druid, version_inventory)
          signature_catalog = SignatureCatalog.new(:digital_object_id => druid)
          version_additions = signature_catalog.version_additions(version_inventory)
          version_additions
        end

        def verification_queries(druid)
          queries = []
          queries
        end

        def verification_files(druid)
          deposit_bag_pathname = Replication::SdrObject.new(druid).deposit_bag_pathname
          files = []
          files << deposit_bag_pathname.to_s
          files << deposit_bag_pathname.join("bag-info.txt").to_s
          files
        end

      end

    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  ARGF.each do |druid|
    dm_robot = Robots::SdrRepo::SdrMigration::MigrationTransfer.new()
    dm_robot.process_item(druid)
  end
end