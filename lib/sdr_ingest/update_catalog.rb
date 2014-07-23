require_relative '../libdir'
require 'boot'

module Robots
  module SdrRepo
    module SdrIngest

      # A robot for creating new entries in the Archive Catalog for the object version
      class UpdateCatalog < SdrRobot

        # class instance variables (accessors defined in SdrRobot parent class)
        @workflow_name = 'sdrIngestWF'
        @step_name = 'update-catalog'

        # set workflow name, step name, log location, log severity level
        def initialize(opts = {})
          super(self.class.workflow_name, self.class.step_name, opts)
        end

        # @param druid [String] The item to be processed
        # @return [void] process an object from the queue through this robot
        #   See LyberCore::Robot#work
        def perform(druid)
          LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter perform")
          update_catalog(druid)
        end

        def update_catalog(druid)
          sdr_object = Replication::SdrObject.new(druid)
          latest_version_id = sdr_object.current_version_id
          sdr_object_version = Replication::SdrObjectVersion.new(sdr_object,latest_version_id)
          sdr_object_version.update_object_data
          sdr_object_version.update_version_data
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
  dm_robot = Robots::SdrRepo::SdrIngest::UpdateCatalog.new()
  dm_robot.start
end
