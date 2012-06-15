require File.join(File.dirname(__FILE__),'libdir')
require 'boot'

module Sdr

  # Adds datastreams to the Fedora object using metadata files from the bagit object.
  class PopulateMetadata < LyberCore::Robots::Robot
    
    def initialize()
      super('sdrIngestWF', 'populate-metadata',
        :logfile => "#{Sdr::Config.logdir}/populate-metadata.log",
        :loglevel => Logger::INFO,
        :options => ARGV[0])
      env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
    end

    # Add the metadata datastreams to the Fedora object
    # Overrides the robot LyberCore::Robot.process_item method.
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      druid = work_item.druid
      fill_datastreams(druid)
    end

    def fill_datastreams(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter populate_metadata")
      bag_pathname = find_bag(druid)
      sedora_object = Sdr::SedoraObject.find(druid)
      set_datastream_content(sedora_object, bag_pathname, 'identityMetadata')
      set_datastream_content(sedora_object, bag_pathname, 'provenanceMetadata')
      sedora_object.save
    rescue ActiveFedora::ObjectNotFoundError => e
      raise LyberCore::Exceptions::FatalError.new("Cannot find object #{druid}",e)
    rescue  Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot process item #{druid}",e)
    end

    # Check to see if the bagit directory exists.
    def find_bag(druid)
      bag_pathname = SdrDeposit.bag_pathname(druid)
      unless bag_pathname.directory?
        raise LyberCore::Exceptions::ItemError.new(druid, "Can't find a bag at #{bag_pathname.to_s}")
      end
      bag_pathname
    end

    # Determine the metadata files full path in the bagit object,
    # make a datastream out of it using the given label, 
    # add it to the fedora object, and save.
    # @raise [LyberCore::Exceptions::FatalError] if we can't find the file
    def set_datastream_content(sedora_object, bag_pathname, dsid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter set_datastream_content for #{dsid}")
      md_pathname = bag_pathname.join('data/metadata',"#{dsid}.xml")
      sedora_object.datastreams[dsid].content = md_pathname.read
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot add #{dsid} datastream for #{sedora_object.pid}",e)
    end
    
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
    dm_robot = SdrIngest::PopulateMetadata.new()
    dm_robot.start
end
