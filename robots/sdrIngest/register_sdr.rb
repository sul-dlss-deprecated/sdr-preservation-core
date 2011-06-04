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
         LyberCore::Log.set_logfile("#{LOGDIR}/register-sdr.log")
         LyberCore::Log.set_level(Logger::INFO)
	       
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
          LyberCore::Log.debug("Processessing druid #{druid}")

          begin
            Fedora::Repository.register(SEDORA_URI)
            LyberCore::Log.debug("DONE : Sedora registration for #{SEDORA_URI}")
          rescue  Exception => e
            raise LyberCore::Exceptions::FatalError.new("Cannot connect to Fedora at url #{SEDORA_URI}",e)
          end

          begin
            obj = ActiveFedora::Base.new(:pid => druid)
            obj.save
            LyberCore::Log.debug("DONE : Created new object #{druid} in Sedora")
          rescue Exception => e
            raise LyberCore::Exceptions::FatalError.new("Object cannot be saved in Sedora",e)
          end

          # Initialize workflow
          # register-sdr workflow status is automatically set to "completed" in sdrIngestWF
          begin
            workflow_xml = File.open(File.join(File.dirname(__FILE__), "..", "..", "config", "workflows", "sdrIngestWF", 'sdrIngestWorkflow.xml'), 'rb') { |f| f.read }
            Dor::WorkflowService.create_workflow('sdr', druid, 'sdrIngestWF', workflow_xml)
            LyberCore::Log.debug("DONE : Created new workflow for #{druid}")
          rescue Exception => e
            raise LyberCore::Exceptions::FatalError.new("Cannot create workflow for #{druid}",e)
          end

          return true

        end  # end process_item

       def process_items()

         # Get the druid list
         # First, get_objects_for_workstep(repository, workflow, completed, waiting)

         LyberCore::Log.info("Getting list of druids to process ... ")

         # Getting list of DOR objects needing deposit to SDR"
         begin
           dor_objects_awaiting_ingest = DorService.get_objects_for_workstep("dor", "googleScannedBookWF", "sdr-ingest-transfer", "sdr-ingest-deposit")
         rescue Exception => e
           raise LyberCore::Exceptions::FatalError.new("Unable to get list of objects needing ingest",e)
         end
           
         # Then get the list of druids from the xml returned in the earlier step
         begin
           druids_awaiting_ingest = DorService.get_druids_from_object_list(dor_objects_awaiting_ingest)
         rescue Exception => e
           raise LyberCore::Exceptions::FatalError.new("Unable to extract new druids from XML",e)
         end

         LyberCore::Log.debug("Number of objects awaiting ingest:  #{druids_awaiting_ingest.length()}")

         # Filter out objects that have already been registered.
         # The last sdr robot complete-deposit sets sdr-ingest-deposit's status to "complete"
         begin
           dor_objects_already_registered = DorService.get_objects_for_workstep("sdr", "sdrIngestWF", "register-sdr", "" )
         rescue Exception => e
           raise LyberCore::Exceptions::FatalError.new("Unable to get list of objects already registered",e)
         end
         
         begin
           druids_already_registered = DorService.get_druids_from_object_list(dor_objects_already_registered)
         rescue Exception => e
           raise LyberCore::Exceptions::FatalError.new("Unable to extract old druids from XML",e)
         end

	       LyberCore::Log.debug("Number of objects already registered :  #{druids_already_registered.length()}")

         # +++++++++++++++++++++++
         # Now that we have the two lists, find objects in the transferred list that are not in the registered list. Because there
         # might be objects that have been registered in a previous run which have not yet made it all the way through to the
         # complete-deposit robot which actually sets the status of sdr-ingest-deposit to "complete"
         # ( In Ruby, this is a simple "set difference", unlike most other languages : newlist = x - y )
         # +++++++++++++++++++++++
         @druids = druids_awaiting_ingest - druids_already_registered
         
         LyberCore::Log.debug("Number of druids to process :  #{@druids.length.to_s}")

         # Now process druids one by one
         i = 0
         while i < @druids.length() do
           begin
             process_druid(@druids[i])
             LyberCore::Log.info("#{@druid} completed")
             @success_count += 1
           rescue LyberCore::Exceptions::FatalError => fatal_error
             raise fatal_error
           rescue Exception => e
             item_error = LyberCore::Exceptions::ItemError.new(@druids[i], "Item error", e)
             LyberCore::Log.exception(item_error)
             @error_count += 1
           end
           i += 1
         end  # end while
         # Print success, error count
         print_stats
         
       end

    end # end of class
end # end of module


# This is the equivalent of a java main method
if __FILE__ == $0
  # If this script is invoked with a specific druid, it will register sdr with that druid only
  begin 
    if(ARGV[0])
      LyberCore::Log.info "Registering SDR with #{ARGV[0]}"
      sdr_bootstrap = SdrIngest::RegisterSdr.new()
      sdr_bootstrap.process_druid(ARGV[0])
    else
      sdr_bootstrap = SdrIngest::RegisterSdr.new()
      sdr_bootstrap.process_items()
    end
  rescue LyberCore::Exceptions::FatalError => fatal_error
    LyberCore::Log.exception(fatal_error)
  rescue Exception => e
    fatal_error = LyberCore::Exceptions::FatalError.new("Fatal error", e)
    LyberCore::Log.exception(fatal_error)
  end
end
