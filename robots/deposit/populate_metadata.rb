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
    
    attr_reader :obj, :bag, :druid, :bag_directory, :identity_metadata
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
      
      # if(self.bag_exists?)
      #   self.get_fedora_object
      #   self.fetch_bag
      #   self.populate_identity_metadata
      # else
      #   # if the bag doesn't exist, raise an error
      #   
      # end
      
    end
    
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
    
    # once you know the druid, go find a bagit object corresponding to that druid id
    # so we can extract the metadata from it
    def fetch_bag
      
    end
    
    def populate_identity_metadata
      if bag_exists? 
        # first, read in the identity metadata xml file
        identityMetadataFile = File.expand_path(@bag + '/data/metadata/identityMetadata.xml')
        @identity_metadata = ActiveFedora::Datastream.new(:pid=>@obj.pid, :dsid=>'IDENTITY', :dsLabel=>'IDENTITY', :blob=>IO.read(identityMetadataFile))
        @obj.add_datastream(@identity_metadata)
        @obj.save
        # add a label 
        # Willy asks: have we decided the datastream types? 
        # by default this is inline xml
        # anything big, make it a managed datastream
        # content is always externally referenced 
        # @test_datastream = ActiveFedora::Datastream.new(:pid=>@test_object.pid, :dsid=>'abcd', :blob=>StringIO.new("hi there"))
      
        # then write it to a datastream
      
        # puts doc.to_xml    
      end  
    end
    
    def populate_provenance_metadata
      
    end
    
    # What does this look like? 
    # What do we mean by populate content? 
    def populate_content
      
    end
    
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Deposit::PopulateMetadata.new(
          'deposit', 'populate-metadata')
  dm_robot.start
end