#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

#require 'dor_service'
require 'dlss_service'
require 'lyber_core'
require 'active-fedora'
require 'logger'

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

         # Take the logfile and level from a config option or command line later
         LyberCore::Log.set_logfile("/tmp/register-sdr.log")
         LyberCore::Log.set_level(Logger::DEBUG)
	       
	       #@logg = Logger.new("/tmp/register-sdr.log")
	       #@logg.level = Logger::DEBUG
         #@logg.formatter = proc{|s,t,p,m|"%5s [%s] (%s) %s :: %s\n" % [s, 
          #                  t.strftime("%Y-%m-%d %H:%M:%S"), $$, p, m]}
   

         # Start the timer
         @start_time = Time.new
         @env = ENV['ROBOT_ENVIRONMENT']
         
	       LyberCore::Log.debug("Start time is :   #{@start_time}")
	
	       LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
         LyberCore::Log.debug("Process ID is : #{$PID}")
         puts DOR_URI

         # Initialize the success and error counts
         @success_count = 0
         @error_count = 0
       end

       # Output the batch's timings and other statistics to STDOUT for capture in a log
       def print_stats
         @end_time = Time.new
         @elapsed_time = @end_time - @start_time
         LyberCore::Log.info("**********************************************")
         LyberCore::Log.info("Total time: " + @elapsed_time.to_s)
         LyberCore::Log.info("Completed objects: " + @success_count.to_s)
         LyberCore::Log.info("Errors: " + @error_count.to_s)
         LyberCore::Log.info("**********************************************")
       end


       # - Creates a *Sedora* object
       # - Initializes the +Deposit+ workflow
       def process_druid(druid)

          begin
	          LyberCore::Log.debug("About to register #{druid} in SEDORA at #{SEDORA_URI}")
            Fedora::Repository.register(SEDORA_URI)
          rescue Errno::ECONNREFUSED => e
            LyberCore::Log.fatal("Cannot connect to Fedora at url #{SEDORA_URI} : #{e.inspect}")
            LyberCore::Log.fatal("#{e.backtrace.join("\n")}")
            raise RuntimeError, "Can't connect to Fedora at url #{SEDORA_URI} : #{e}"
            #return nil
          end
          LyberCore::Log.info("DONE : Sedora registration")
          puts "DONE : Sedora registration"

          LyberCore::Log.debug("Druid in Sedora will be : #{druid}")
        
          begin
            obj = ActiveFedora::Base.new(:pid => druid)
            LyberCore::Log.debug("Save #{druid} in Sedora")
            obj.save
          rescue Exception => e
            #raise "error in saving"
            puts "ERROR : Object cannot be saved in Sedora"
            LyberCore::Log.fatal("Object cannot be saved in Sedora :  #{e.inspect}")
            LyberCore::Log.fatal("#{e.backtrace.join("\n")}")
            raise RuntimeError, "Object cannot be saved in Sedora"
            #return nil
          end

          puts "DONE : Create new object in Sedora"

          # Initialize workflow
          workflow_xml = File.open(File.join(File.dirname(__FILE__), "..", "..", "config", "workflows", "sdrIngestWF", 'sdrIngestWorkflow.xml'), 'rb') { |f| f.read }
          begin
            Dor::WorkflowService.create_workflow('sdr', druid, 'sdrIngestWF', workflow_xml)
            # looks like there is no exception raised by WorkflowService yet ? when it is do :
          rescue Exception => e
            puts "ERROR : Cannot create workflow for #{druid}"
            LyberCore::Log.fatal("Cannot create workflow #{workflow_xml} : #{e.inspect}")
            LyberCore::Log.fatal("#{e.backtrace.join("\n")}")
            raise RuntimeError, "Cannot create workflow #{workflow_xml} : #{e}" 
          end

          puts "DONE : Create new workflow for #{druid}"

          # Dont do this. Creating a new workflow with "completed" status for register-sdr is enough
          # update register-sdr status to "completed" in sdrIngestWF
          #result = Dor::WorkflowService.update_workflow_status("sdr", druid, "sdrIngestWF", "register-sdr", "completed")
          #raise "Update workflow \"register-sdr\" failed." unless result


          return true

        end  # end process_item

       def process_items()

         # Get the druid list
         # First, get_objects_for_workstep(repository, workflow, completed, waiting)

         puts "\nGetting list of druids to process ... "
         LyberCore::Log.info("Getting list of druids to process ... ")

         #puts "getting list of objects that have been transferred"
         begin
           druids_already_transferred_list_xml = DorService.get_objects_for_workstep("dor", "googleScannedBookWF", "sdr-ingest-transfer", "sdr-ingest-deposit")
         rescue => e
           LyberCore::Log.info("There are either no objects available, or we cannot get the list of objects that have been transferred : #{e.inspect}")
           LyberCore::Log.info("#{e.backtrace.join("\n")}")
           raise e
         end
           
         # Then get the list of druids from the xml returned in the earlier step
         begin
           druids_already_transferred = DorService.get_druids_from_object_list(druids_already_transferred_list_xml)
         rescue => e
           LyberCore::Log.error("Cannot get list of druids from the transferred object list : #{e.inspect}")
           LyberCore::Log.error("#{e.backtrace.join("\n")}")
           raise e
         end

         # ^^^^^^^^^^^^^ debugging ^^^^^^^^^^^^^
         #puts "\n \n DRUIDS already transferred length =   "
         #puts druids_already_transferred.length()
         LyberCore::Log.debug("Number of objects already transferred :  #{druids_already_transferred.length()}")
         #puts "\n ========  DRUIDS already transferred =========="
         #puts druids_already_transferred
         # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

         # +++++++++++++++++++++++
         # druids_already_transferred is the big list of all objects that are waiting for sdr-ingest-deposit to be completed.
         # From this list filter out objects that have already been registered.
         # The last sdr robot complete-deposit sets sdr-ingest-deposit's status to "complete"
         # +++++++++++++++++++++++
	       druids_already_registered = Array.new
         # druids_already_registered_xml = DorService.get_objects_for_workstep("sdr", "sdrIngestWF", "register-sdr", "complete-deposit" )
         begin
           druids_already_registered_xml = DorService.get_objects_for_workstep("sdr", "sdrIngestWF", "register-sdr", "" )
         rescue => e
           LyberCore::Log.info("There are no objects that have already been registered : #{e.inspect}")
           #LyberCore::Log.error("#{e.backtrace.join("\n")}")
           #raise e
         end
         
         if (druids_already_registered_xml != nil)
           druids_already_registered = DorService.get_druids_from_object_list(druids_already_registered_xml)
         end

         # ^^^^^^^^^^^^^ debugging ^^^^^^^^^^^^^
         #puts "\n \n DRUIDS already registered  length =   "
         #puts druids_already_registered.length()
	       LyberCore::Log.debug("Number of objects already registered :  #{druids_already_registered.length()}")
         #puts " \n \n ========  DRUIDS already registered  =========="
         #puts druids_already_registered
         # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


         # +++++++++++++++++++++++
         # Now that we have the two lists, find objects in the transferred list that are not in the registered list. Because there
         # might be objects that have been registered in a previous run which have not yet made it all the way through to the
         # complete-deposit robot which actually sets the status of sdr-ingest-deposit to "complete"
         # ( In Ruby, this is a simple "set difference", unlike most other languages : newlist = x - y )
         # +++++++++++++++++++++++
         @druids = druids_already_transferred - druids_already_registered
         
         LyberCore::Log.debug("Number of druids to process :  #{@druids.length.to_s}")
	       
         puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
         puts "About to process " + @druids.length.to_s  + " druids"

         #if (@druids.length() == 0)
         #  puts "There are NO druids to process"
         #end

         # Now process druids one by one
         i = 0

         while i < @druids.length() do
           begin
             puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
             puts "Processing " + @druids[i]
             #puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
             begin
               process_druid(@druids[i])
               @success_count += 1
               #puts "YESSSSSSSSSSSSSSSSS!!!!"
             rescue
               @error_count += 1
               #puts "Errrrrrrrrrrroooooooooorrrrrrrrrrrr"
             end
             i += 1
           end
         end  # end while
         # Print success, error count
         print_stats
         
         #should we close log here ? if we see reason not to, comment the following line
	       LyberCore::Log.close
       end

    end # end of class
end # end of module


# This is the equivalent of a java main method
if __FILE__ == $0
  # If this script is invoked with a specific druid, it will register sdr with that druid only
  begin 
    if(ARGV[0])
      puts "Registering SDR with #{ARGV[0]}"
      sdr_bootstrap = SdrIngest::RegisterSdr.new()
      sdr_bootstrap.process_druid(ARGV[0])
      #sdr_bootstrap.print_stats()
    else
      sdr_bootstrap = SdrIngest::RegisterSdr.new()
      sdr_bootstrap.process_items()
    end
  rescue => e
    puts e.message
  end
  puts "Register SDR done\n"
end
