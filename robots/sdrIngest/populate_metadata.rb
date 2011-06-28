#!/usr/bin/env ruby
# Author::    Bess Sadler  (mailto:bess@stanford.edu)
# Date::      13 May 2010

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'logger'
require 'English'

module SdrIngest
  
  # Adds datastreams to the Fedora object using metadata files from the bagit object.
  class PopulateMetadata < LyberCore::Robots::Robot
    
    # @return [Fedora object] The object to which datastreams will be added
    attr_reader :obj
    
    # @return [String] The full path of the bag to fetch metadata from
    attr_reader :bag
    
    # @return [String] The druid of the current workitem
    attr_reader :druid 

    # @return [Fedora datastream] identityMetadata
    attr_reader :identity_metadata
    
    # @return [Fedora datastream] provenanceMetadata
    attr_reader :identity_metadata, :provenance_metadata

    def initialize()
      super('sdrIngestWF', 'populate-metadata',
        :logfile => "#{LOGDIR}/populate-metadata.log", 
        :loglevel => Logger::INFO,
        :options => ARGV[0])
      @env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
    end

    # Add the metadata datastreams to the Fedora object
    # Overrides the robot LyberCore::Robot.process_item method.
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      # Identifiers
      @druid = work_item.druid
      raise LyberCore::Exceptions::ItemError.new(druid, "Can't find a bag at #{@bag}") unless self.bag_exists?
      raise LyberCore::Exceptions::ItemError.new(druid, "Can't load sedora object for #{@druid}") unless self.get_fedora_object
      self.populate_identity_metadata
      self.populate_provenance_metadata
      @obj.save
    end
    
    # Check to see if the bagit directory exists.
    def bag_exists?
      @bag = SdrDeposit.local_bag_path(self.druid)
      File.directory? @bag
    end
    
    # Fetch the fedora object from the repository so we can attach datastreams to it
    # @raise [LyberCore::Exceptions::FatalError] if we can't find the object
    def get_fedora_object
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter get_fedora_object")
      LyberCore::Log.debug("Registering #{SEDORA_URI}")
      Fedora::Repository.register(SEDORA_URI)
      @obj = ActiveFedora::Base.load_instance(@druid)
      LyberCore::Log.debug("Loaded druid #{@druid} into object #{@obj}")
    rescue  Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot connect to Fedora at url #{SEDORA_URI}",e)
    end
    
    # Determine the metadata files full path in the bagit object,
    # make a datastream out of it using the given label, 
    # add it to the fedora object, and save.
    # @raise [LyberCore::Exceptions::FatalError] if we can't find the file
    def populate_metadata(filename,label)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter populate_metadata")
      mdfile = File.expand_path(@bag + '/data/metadata/' + filename)
      LyberCore::Log.debug("mdfile is : #{mdfile}")
      md = ActiveFedora::Datastream.new(:pid=>@obj.pid, :dsid=>label, :dsLabel=>label, :blob=>IO.read(mdfile))
      @obj.add_datastream(md)
      return md
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot add #{label} datastream for #{@obj.pid}",e)
    end

    # Add the identityMetadata datastream
    def populate_identity_metadata
      @identity_metadata = populate_metadata('identityMetadata.xml','identityMetadata')
    end
    
    # Add the provenanceMetadata datastream
    def populate_provenance_metadata
      @provenance_metadata = populate_metadata('provenanceMetadata.xml','provenanceMetadata')
    end
    
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
    dm_robot = SdrIngest::PopulateMetadata.new()
    dm_robot.start
end
