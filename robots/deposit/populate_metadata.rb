#!/usr/bin/env ruby

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
    
    attr_reader :obj, :bag, :druid, :bag_directory
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
      @bag = SDR_DEPOSIT_DIR + '/' + @druid.split(":")[1]
      
      self.get_fedora_object
      self.fetch_bag
      self.populate_identity_metadata
    end
    
    # fetch the fedora object from the repository so we can attach datastreams to it
    # throw an error if we can't find the object
    def get_fedora_object
      Fedora::Repository.register(SEDORA_URI)
      @obj = ActiveFedora::Base.load_instance(@druid)
    end
    
    # once you know the druid, go find a bagit object corresponding to that druid id
    # so we can extract the metadata from it
    def fetch_bag
      
    end
    
    def populate_identity_metadata
      # first, read in the identity metadata xml file
      @identityMetadataFile = @bag + '/data/metadata/identityMetadata.xml'
      doc = Nokogiri::XML(open(@bag + '/data/metadata/identityMetadata.xml'))
      
      # then write it to a datastream
      
      puts doc.to_xml
    end
    
    
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Deposit::PopulateMetadata.new(
          'deposit', 'populate-metadata')
  dm_robot.start
end