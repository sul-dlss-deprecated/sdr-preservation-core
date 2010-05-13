#!/usr/bin/env ruby
# Bess Sadler
# bess@stanford.edu
# 13 May 2010

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'

# +Deposit+ initializes the SdrIngest workflow by registering the object and transferring 
# the object from DOR to SDR's staging area.
#
# The most up to date description of the deposit workflow is always in config/workflows/deposit/depositWorkflow.xml. 
# (Content included below.)
# :include:config/workflows/deposit/depositWorkflow.xml

module Deposit

# Populates metadata for an SDR object by reading the appropriate XML files
# from the bagit object and attaching them as datastreams in Sedora
# - notifies DOR of success by: <b><i>need to be filled in</i></b>
# - notifies DOR of failure by: <i><b>need to be filled in</b></i>

  class PopulateMetadata < LyberCore::Robot
    
    attr_reader :obj, :bag, :druid, :bag_directory, :identity_metadata, :content_metadata, :provenance_metadata
    attr_writer :bag_directory
    
    def initialize(string1,string2)
      super(string1,string2)
      # by default, get the bags from the SDR_DEPOSIT_DIR
      # this can be explicitly changed if necessary
      @bag_directory = SDR_DEPOSIT_DIR
    end

    # Override the robot LyberCore::Robot.process_item method.
    # * Makes use of the Robot Framework FileUtilities.
    def process_item(work_item)
      # Identifiers
      @druid = work_item.druid
    
      raise IOError, "Can't find a bag at #{@bag}" unless self.bag_exists?
      raise IOError, "Can't load sedora object for #{@druid}" unless self.get_fedora_object
      self.populate_identity_metadata
      self.populate_provenance_metadata
      self.populate_content_metadata
    end
    
    # Check to see if the bagit directory exists.
    # It does not check the validity of the bag, it assumes this has already happened.
    def bag_exists?
      @bag = @bag_directory + '/' + self.druid.split(":")[1]
      File.directory? @bag
    end
    
    # fetch the fedora object from the repository so we can attach datastreams to it
    # throw an error if we can't find the object
    def get_fedora_object
      begin
        Fedora::Repository.register(SEDORA_URI)
      rescue Errno::ECONNREFUSED => e
        raise RuntimeError, "Can't connect to Fedora at url #{SEDORA_URI} : #{e}"
      end
      @obj = ActiveFedora::Base.load_instance(@druid)
    end
    
    # Go grab the given filename from the bagit object, 
    # make a datastream out of it using the given label, 
    # attach it to the fedora object, and save. 
    # Throw an error if you can't find a bag or if you can't find the file
    def populate_metadata(filename,label)
      mdfile = File.expand_path(@bag + '/data/metadata/' + filename)
      md = ActiveFedora::Datastream.new(:pid=>@obj.pid, :dsid=>label, :dsLabel=>label, :blob=>IO.read(mdfile))
      @obj.add_datastream(md)
      @obj.save
      return md
    end
    
    def populate_identity_metadata
      @identity_metadata = populate_metadata('identityMetadata.xml','IDENTITY')
    end
    
    def populate_provenance_metadata
      @provenance_metadata = populate_metadata('provenanceMetadata.xml','PROVENANCE')
    end
    
    def populate_content_metadata
      @content_metadata = populate_metadata('contentMetadata.xml','CONTENTMD')
    end
    
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Deposit::PopulateMetadata.new(
          'deposit', 'populate-metadata')
  dm_robot.start
end