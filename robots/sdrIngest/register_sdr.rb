#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'dlss_service'
require 'lyber_core'
require 'active-fedora'
require 'logger'

module SdrIngest

  # Creates +Sedora+ objects and workflow datastreams.
  class RegisterSdr < LyberCore::Robots::Robot

    def initialize()
      super('sdrIngestWF', 'register-sdr',
        :logfile => "#{LOGDIR}/register-sdr.log",
        :loglevel => Logger::INFO,
        :options => ARGV[0])
      env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
      initialize_fedora_repository(SEDORA_URI)
    end

    # Initialize the fedora repository
    def initialize_fedora_repository(fedora_uri)
      Fedora::Repository.register(fedora_uri)
      LyberCore::Log.debug("DONE : Sedora registration for #{fedora_uri}")
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot connect to Fedora at url #{fedora_uri}", e)
    end

    # - Creates a *Sedora* object
    # - Adds the +sdrIngestWF+ datastream
    def process_item(work_item)
      druid = work_item.druid
      LyberCore::Log.debug("Processessing druid #{druid}")
      fedora_object = add_fedora_object(druid)
      fedora_object = get_fedora_object(druid) if fedora_object.nil?
      add_workflow_datastream(fedora_object)
      return true
    end

    # Add new or retrieve existing object having pid = druid
    def add_fedora_object(druid)
      # Creatig a new Fedora object will be the usual case
      object = ActiveFedora::Base.new(:pid => druid)
      object.save
      LyberCore::Log.debug("DONE : Created new object #{druid} in Sedora")
      return object
    rescue Fedora::ServerError => e
      if (e.message.include?('ObjectExistsException'))
        # puts 'object exists'
        return nil
      else
        raise LyberCore::Exceptions::FatalError.new("Object cannot be created in Sedora", e)
      end
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Object cannot be created in Sedora", e)
    end

    # retrieve existing object having pid = druid
    def get_fedora_object(druid)
      object = ActiveFedora::Base.load_instance(druid)
      LyberCore::Log.debug("Loading druid #{druid} into object #{object}")
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Object cannot be retrieved from Sedora", e)
      return object
    end

    # Adding the sdrIngestWF datastream for the workflow
    # The workflow database entries were previously created by sdr-ingest-transfer robot
    # of the separate workflow that is submitting objects to be ingested
    # Reference: https://wiki.duraspace.org/display/FCR30/REST+API#RESTAPI-addDatastream
    def add_workflow_datastream(fedora_object)
      begin
        druid = fedora_object.pid
         label = 'sdrIngestWF'
         ds = ActiveFedora::Datastream.new(:pid => druid ,
           :dsIS => label, :dsLabel => label,
           :controlGroup => "E", :versionable => "false", :checksum => "DISABLED",
           :dsLocation => "#{WORKFLOW_URI}/sdr/objects/#{druid}/workflows/sdrIngestWF"
         )
         fedora_object.add_datastream(ds)
       rescue Exception => e
         raise LyberCore::Exceptions::FatalError.new("#{label} datastream cannot be saved in Sedora", e)
       end

    end

  end

end 

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::RegisterSdr.new()
  dm_robot.start
end
