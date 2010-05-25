#!/usr/bin/env ruby
# Xinlei Qiu
# xinlei@stanford.edu
# 13 May 2010

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'

# +Deposit+ initializes the SdrIngest workflow by registering the object and transferring 
# the object from DOR to SDR's staging area.
#
# The most up to date description of the deposit workflow is always in config/workflows/deposit/depositWorkflow.xml. 
# (Content included below.)
# :include:config/workflows/deposit/depositWorkflow.xml

module SdrIngest
  
  class CompleteDeposit < LyberCore::Robot
    attr_reader :obj, :druid;
    attr_writer :bag_directory;
    
    
    def initialize(string1,string2)
      super(string1,string2)
      # by default, get the bags from the SDR_DEPOSIT_DIR
      # this can be explicitly changed if necessary
      @bag_directory = SDR_DEPOSIT_DIR
    end
    
    def process_item(work_item)
      @druid = work_item.druid
      result = Dor::WorkflowService.update_workflow_status("sdr", druid, "sdrIngestWF", "complete-deposit", "completed")
      raise "Update workflow \"complete-deposit\" failed" unless result
      
      raise "Cannot load Sedora object" unless get_fedora_object
      
      update_provenance(druid, "deposit complete")
    end
    
    def update_provenance (druid, provenance)
      return true
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
