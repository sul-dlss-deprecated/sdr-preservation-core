require_relative '../libdir'
require 'boot'

module Robots
  module SdrRepo
    module SdrIngest

      # A robot for creating new entries in the Archive Catalog for the object version
      class CreateReplica < SdrRobot

        # class instance variables (accessors defined in SdrRobot parent class)
        @workflow_name = 'sdrIngestWF'
        @step_name = 'create-replica'

        # set workflow name, step name, log location, log severity level
        def initialize(opts = {})
          super(self.class.workflow_name, self.class.step_name, opts)
        end

        # @param druid [String] The item to be processed
        # @return [void] process an object from the queue through this robot
        #   See LyberCore::Robot#work
        def perform(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
          create_replica(druid)
        end

        # @param druid [String] The item to be processed
        # @return [void] Craeate a replica bag for the new object version in the replica cache
        #   and update the Archive Catalog's replica table
        def create_replica(druid)
          sdr_object = Replication::SdrObject.new(druid)
          latest_version_id = sdr_object.current_version_id
          sdr_object_version = Replication::SdrObjectVersion.new(sdr_object,latest_version_id)
          replica = sdr_object_version.create_replica
          replica.get_bag_data
          replica.update_replica_data
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
    dm_robot = Robots::SdrRepo::SdrIngest::CreateReplica.new()
    dm_robot.process_item(druid)
  end
end
