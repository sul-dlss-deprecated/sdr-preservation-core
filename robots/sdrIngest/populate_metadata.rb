#!/usr/bin/env ruby
# Author::    Bess Sadler  (mailto:bess@stanford.edu)
# Date::      13 May 2010

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'logger'
require 'English'

#:title:The SdrIngest Workflow
#= The SdrIngest Workflow
#The +SdrIngest+ workflow takes objects from Dor's queue and deposits them into SDR.
#The most up to date description of the deposit workflow is always in 
#config/workflows/sdrIngest/sdrIngestWorkflow.xml. (Content included below.)
#:include:config/workflows/sdrIngest/sdrIngestWorkflow.xml
module SdrIngest
  
  # PopulateMetadata finds a stub object in Sedora and 
  # populates its datastreams with the contents from a bagit object.
  class PopulateMetadata < LyberCore::Robots::Robot
    
    # the fedora object to operate on
    attr_reader :obj
    
    # the bag to fetch metadata from
    attr_reader :bag
    
    # the druid of the current workitem
    attr_reader :druid 

    # Accessor method for datastream
    attr_reader :identity_metadata, :provenance_metadata
    
    # Override the LyberCore::Robot initialize method so we can set object attributes during initialization
    def initialize()
      super('sdrIngestWF', 'populate-metadata',
        :logfile => "#{LOGDIR}/populate-metadata.log", 
        :loglevel => Logger::INFO,
        :options => ARGV[0])

      @env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
      
    end

    # Override the robot LyberCore::Robot.process_item method.
    # * Makes use of the Robot Framework FileUtilities.
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
    # It does not check the validity of the bag, it assumes this has already happened.
    def bag_exists?
      @bag = SdrDeposit.local_bag_path(self.druid)
      File.directory? @bag
    end
    
    # fetch the fedora object from the repository so we can attach datastreams to it
    # throw an error if we can't find the object
    def get_fedora_object
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter get_fedora_object")
      LyberCore::Log.debug("Registering #{SEDORA_URI}")
      Fedora::Repository.register(SEDORA_URI)
      @obj = ActiveFedora::Base.load_instance(@druid)
      LyberCore::Log.debug("Loaded druid #{@druid} into object #{@obj}")
    rescue  Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot connect to Fedora at url #{SEDORA_URI}",e)
    end
    
    # Go grab the given filename from the bagit object, 
    # make a datastream out of it using the given label, 
    # attach it to the fedora object, and save. 
    # Throw an error if you can't find a bag or if you can't find the file
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
    
    def populate_identity_metadata
      @identity_metadata = populate_metadata('identityMetadata.xml','identityMetadata')
    end
    
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
