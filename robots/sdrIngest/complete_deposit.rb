#!/usr/bin/env ruby
# Xinlei Qiu
# xinlei@stanford.edu
# 13 May 2010

$:.unshift File.join(File.dirname(__FILE__), "../../../../", "lybots/models/provenance_metadata")

require File.expand_path(File.dirname(__FILE__) + '/../boot')
require File.expand_path(File.dirname(__FILE__) + '/provenance_metadata')
require File.expand_path(File.dirname(__FILE__) + '/workflow_model')
#require File.expand_path(File.dirname(__FILE__) + '/sdr_service')

require 'lyber_core'
require 'nokogiri'

# +Deposit+ initializes the SdrIngest workflow by registering the object and transferring 
# the object from DOR to SDR's staging area.
#
# The most up to date description of the deposit workflow is always in config/workflows/deposit/depositWorkflow.xml. 
# (Content included below.)
# :include:config/workflows/deposit/depositWorkflow.xml

module SdrIngest
  
  class CompleteDeposit < LyberCore::Robot
    attr_reader :obj, :druid, :sdr_provXML;
    attr_writer :bag_directory;
        
    def initialize(string1,string2)
      super(string1,string2)
      # by default, get the bags from the SDR_DEPOSIT_DIR
      # this can be explicitly changed if necessary
      @bag_directory = SDR_DEPOSIT_DIR
    end
    
    def process_item(work_item)
      @druid = work_item.druid
      raise "Cannot load Sedora object." unless get_fedora_object

      # Update provenance
      raise "Failed to update provenance to include Deposit completion." unless update_provenance

      # Update DOR workflow 
      result = Dor::WorkflowService.update_workflow_status("dor", druid, "googleScannedBookWF", "sdr-ingest-complete", "completed")
      raise "Update workflow \"complete-deposit\" failed." unless result
    end
    
    def update_provenance 
      # Create (and add?) new SDR prov datastream
      create_sdr_provenance
      
      # retrieve existing prov
      prov = retrieve_existing_provenance
      #raise "Provenance metadata datastream not found." unless prov       

      # append new prov to existing
      append_provenance(prov, sdr_provXML)

      # delete existing provenance datastream
      # make sure to check the old one is indeed deleted.
      
      # Add prov back in
      
      ds_id = "PROVENANCE"
      ds_label = "Provenance Metadata"
#      self.obj.add_datastream(:pid=>@druid, prov.to_s) 
#self.obj.add_datastream(:pid => @druid, :dsid=>ds_id, :dsLabel=>ds_label, :content=>prov.to_s) 
      return true
    end
 
    def append_provenance(prov_str, sdr_agent)
      provXML = Nokogiri::XML(prov_str)
      #provXML.root << sdr_provXML.root
    end
    
    def retrieve_existing_provenance
      ds_id = "PROVENANCE"
      ds_label = "Provenance Metadata"
      prov = self.obj.datastreams[ds_id]
      
    end
    
    def create_sdr_provenance
      #workflowXML = SdrService.get_datastream(@druid, 'sdrIngestWF')
      #workflowRoxml = WorkflowModel.from_xml(workflowXML)
      #events = workflowRoxml.get_events()
      event = Event.new
      event.event = "SDR event"
      event.who="SDR-robot"
      event.when = "whenever"
      
      what = What.new
      what.object = @druid
#      what.event = events 
      what.event = [event]
      
      agent = Agent.new
      agent.name = "SDR"
      agent.what = what
      
      @sdr_provXML = agent.to_xml
# Why would this cause all the tests to fail?
#      puts "SDR Agent: " + agent.to_xml
    end
    
    # fetch the fedora object from the repository so we can attach datastreams to it
    # throw an error if we can't find the object
    def get_fedora_object
      begin
        Fedora::Repository.register(SEDORA_URI)
        @obj = ActiveFedora::Base.load_instance(@druid)
      rescue Errno::ECONNREFUSED => e
        raise RuntimeError, "Can't connect to Fedora at url #{SEDORA_URI} : #{e}"   
        return nil     
      rescue
        return nil
      end
    end
  end
  
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::CompleteDeposit.new(
          'sdrIngest', 'complete-deposit')
  dm_robot.start
end
