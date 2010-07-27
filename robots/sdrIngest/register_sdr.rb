#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'dor_service'
require 'lyber_core'
require 'active-fedora'

module SdrIngest

# Creates +Sedora+ objects and bootstrapping the workflow.

    class RegisterSdr 
       
       # Array of workitem objects to be processed
       attr_reader :druids
       
       # The timings for the batch run
       attr_reader :start_time
       attr_reader :end_time
       attr :elapsed_time
       
       # The tally of how many items have been processed
       attr_accessor :success_count
       attr_accessor :error_count
       
       def initialize()
  
         # Start the timer
         @start_time = Time.new
         
         # Initialize the success and error counts
         @success_count = 0
         @error_count = 0
       end
       
       def process_items()
    
          # Start the timer
          #@start_time = Time.new
          
          # Initialize the success and error counts
          #@success_count = 0
          #@error_count = 0
          
         # Get the druid list
         # First, get_objects_for_workstep(repository, workflow, completed, waiting)
         #puts "getting object list"
         object_list_xml = DorService.get_objects_for_workstep("dor", "googleScannedBookWF", "sdr-ingest-transfer", "sdr-ingest-deposit")
      
         # Then get the list of druids from the xml returned in the earlier step
         #puts "getting druids"
         @druids = DorService.get_druids_from_object_list(object_list_xml)
      
         # debugging
         #puts @druids.length()
 
         # Process druids one by one
         i = 0
        
         while i < @druids.length() do
           begin
             puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
             puts "Processing " + @druids[i]
             #puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
             if (process_druid(@druids[i]) == nil) 
               @error_count += 1
               #puts "Errrrrrrrrrrroooooooooorrrrrrrrrrrr"
             else
               #puts "YESSSSSSSSSSSSSSSSS!!!!"
               @success_count += 1
             end
             i += 1
           end
      
         end  # end while
         # Print success, error count
         print_stats

       end 
  
  
       # Output the batch's timings and other statistics to STDOUT for capture in a log
       def print_stats
         @end_time = Time.new
         @elapsed_time = @end_time - @start_time
         puts "\n \n"
         puts "**********************************************"
         puts "Total time: " + @elapsed_time.to_s + "\n"
         puts "Completed objects: " + @success_count.to_s + "\n"
         puts "Errors: " + @error_count.to_s + "\n"
         puts "**********************************************"
       end
  
  
       # - Creates a *Sedora* object
       # - Initializes the +Deposit+ workflow
       def process_druid(druid)
    
          begin
            Fedora::Repository.register(SEDORA_URI)
          rescue Errno::ECONNREFUSED => e
            raise RuntimeError, "Can't connect to Fedora at url #{SEDORA_URI} : #{e}"  
            return nil
          end
          puts "DONE : Sedora registration"
          
         
          #puts "druid in sedora will be" + druid
          begin
            obj = ActiveFedora::Base.new(:pid => druid)
            #puts "save new object in sedora"
            obj.save
          rescue Exception => e
            #raise "error in saving"
            puts "ERROR : Object cannot be saved in Sedora"
            return nil
          end
             
          puts "DONE : Create new object in Sedora"

          # Initialize workflow
          workflow_xml = File.open(File.join(File.dirname(__FILE__), "..", "..", "config", "workflows", "sdrIngest", 'sdrIngestWorkflow.xml'), 'rb') { |f| f.read }
          Dor::WorkflowService.create_workflow('sdr', druid, 'sdrIngestWF', workflow_xml) 
           
          puts "DONE : Create new workflow for #{druid}"
           
          return true
         
        end  # end process_item
  
    end # end of class
end # end of module 

# This is the equivalent of a java main method
if __FILE__ == $0
  # If this script is invoked with a specific druid, it will register sdr with that druid only
  if(ARGV[0])
    puts "Registering SDR with #{ARGV[0]}"
    sdr_bootstrap = SdrIngest::RegisterSdr.new()
    sdr_bootstrap.process_druid(ARGV[0])
    sdr_bootstrap.print_stats()
  else
    sdr_bootstrap = SdrIngest::RegisterSdr.new()
    sdr_bootstrap.process_items() 
  end
  puts "Register SDR done"   
end

