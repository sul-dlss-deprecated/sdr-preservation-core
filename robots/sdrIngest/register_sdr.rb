#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'dor_service'
require 'lyber_core'
require 'active-fedora'

module SdrIngest

# Creates +Sedora+ objects and bootstrapping the workflow.
  #class RegisterSdr < LyberCore::Robot
    class RegisterSdr 
       
       # Array of workitem objects to be processed
       attr_reader :druids
       
       def self.start()
    
         # Get the druid list
         # First, get_objects_for_workstep(repository, workflow, completed, waiting)
         puts "getting object list"
         object_list_xml = DorService.get_objects_for_workstep("dor", "googleScannedBookWF", "sdr-ingest-transfer", "sdr-ingest-deposit")
      
         # Then get the list of druids from the xml returned in the earlier step
         puts "getting druids"
         @druids = DorService.get_druids_from_object_list(object_list_xml)
      
         # debugging
         puts @druids.length()
         #puts @druids
      
         # put in a loop
         while @druids.length() > 0 do
           begin
             puts @druids[0]
             process_item(@druids[0])
           end
      
         end  # end while
       end 
  
  
       # - Creates a *Sedora* object
       # - Initializes the +Deposit+ workflow
       def self.process_item(druid)
    
          puts "registering in sedora"
          begin
            Fedora::Repository.register(SEDORA_URI)
          rescue Errno::ECONNREFUSED => e
            raise RuntimeError, "Can't connect to Fedora at url #{SEDORA_URI} : #{e}"  
            return nil
          end
          
          puts "create new object in sedora"
          puts "druid in sedora will be" + druid
          begin
            obj = ActiveFedora::Base.new(:pid => druid)
          
            puts "save new object in sedora"
      
            obj.save
          rescue Exception => e
                 raise "error in saving"
          end
            
            
          
          puts "obj saved"

          workflow_xml = File.open(File.join(File.dirname(__FILE__), "..", "..", "config", "workflows", "sdrIngest", 'sdrIngestWorkflow.xml'), 'rb') { |f| f.read }
          Dor::WorkflowService.create_workflow('sdr', druid, 'sdrIngestWF', workflow_xml)  
         
        end
  
    end # end of class
end # end of module 

# This is the equivalent of a java main method
if __FILE__ == $0
  SdrIngest::RegisterSdr.start()
end

