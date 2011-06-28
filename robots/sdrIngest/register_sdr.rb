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
    # - Initializes the +sdrIngestWF+ workflow
    def process_druid(druid)
      LyberCore::Log.debug("Processessing druid #{druid}")

      begin
        Fedora::Repository.register(SEDORA_URI)
        LyberCore::Log.debug("DONE : Sedora registration for #{SEDORA_URI}")
      rescue Exception => e
        raise LyberCore::Exceptions::FatalError.new("Cannot connect to Fedora at url #{SEDORA_URI}", e)
      end

      begin
        obj = ActiveFedora::Base.new(:pid => druid)
        obj.save
        LyberCore::Log.debug("DONE : Created new object #{druid} in Sedora")

        # Adding the sdrIngestWF datastream for the workflow
        # The workflow database entries were previously created by sdr-ingest-transfer robot
        # of the separate workflow that is submitting objects to be ingested
        # Reference: https://wiki.duraspace.org/display/FCR30/REST+API#RESTAPI-addDatastream
        label = 'sdrIngestWF'
        ds = ActiveFedora::Datastream.new(:pid => druid,
                                          :dsid => 'sdrIngestWF', :dsLabel => 'sdrIngestWF',
                                          :controlGroup => "E", :versionable => "false", :checksum => "DISABLED",
                                          :dsLocation => "#{WORKFLOW_URI}/sdr/objects/#{druid}/workflows/sdrIngestWF"
        )
        obj.add_datastream(ds)


      rescue Exception => e
        raise LyberCore::Exceptions::FatalError.new("Object cannot be saved in Sedora", e)
      end

      return true

    end

    # end process_item

    # Obtain the list of druids to be registered and process each one
    def process_items()

      # Get the druid list
      # First, get_objects_for_workstep(repository, workflow, completed, waiting)

      LyberCore::Log.info("Getting list of druids to process ... ")

      begin
        dor_objects_to_register = DorService.get_objects_for_workstep("sdr", "sdrIngestWF", "start-ingest", "register-sdr")
      rescue Exception => e
        raise LyberCore::Exceptions::FatalError.new("Unable to get list of objects to register", e)
      end

      begin
        @druids = DorService.get_druids_from_object_list(dor_objects_to_register)
      rescue Exception => e
        raise LyberCore::Exceptions::FatalError.new("Unable to extract druids from XML", e)
      end

      LyberCore::Log.debug("Number of objects to register :  #{@druids.length()}")

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
      end # end while
      # Print success, error count
      print_stats

    end

  end # end of class
end # end of module


# This is the equivalent of a java main method
if __FILE__ == $0
  # If this script is invoked with a specific druid, it will register sdr with that druid only
  begin
    if (ARGV[0])
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
