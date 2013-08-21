require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # A robot for creating +Sedora+ objects and workflow datastreams unless they exist
  class RegisterSdr < SdrRobot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'register-sdr'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      druid=work_item.druid
      accession_status = get_workflow_status('dor', druid, 'accessionWF', 'sdr-ingest-transfer')
      unless accession_status == 'completed'
        raise LyberCore::Exceptions::ItemError.new(
                  druid, "accessionWF:sdr-ingest-transfer status is #{accession_status}")
      end
      register_item(druid)
      # temporary measure until sdr-ingest-transfer creates this row in workflow table
      update_workflow_status('sdr',druid, 'sdrIngestWF', 'ingest-cleanup', 'waiting') if @workflow_name == 'sdrIngestWF'
    end

    # @param druid [String] The object identifier
    # @return [SedoraObject]
    # - Creates a *Sedora* object unless it already exists
    # - Adds the +sdrIngestWF+ datastream to the Sedora object unless it already exists
    def register_item(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter register_item")
      if SedoraObject.exists?(druid)
        sedora_object = SedoraObject.find(druid)
      else
        sedora_object = SedoraObject.new(:pid=>druid)
        sedora_object.save
      end
      sedora_object.set_workflow_datastream_location
      sedora_object
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Sedora Object cannot be found or created", e)
    end

    def verification_queries(druid)
      user_password = "#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}"
      fedora_url = Sdr::Config.sedora.url.sub('//',"//#{user_password}@")
      queries = []
      queries << [
          "#{fedora_url}/objects/#{druid}?format=xml", 200,
          /<objectProfile/ ]
      queries << [
          "#{fedora_url}/objects/#{druid}/datastreams?format=xml",
           200, /<objectDatastreams/ ]
      queries << [
          "#{fedora_url}/objects/#{druid}/datastreams/workflows?format=xml",
          200, /<dsLabel>Workflows<\/dsLabel>/ ]
      queries
    end

    def verification_files(druid)
      files = []
      files
    end


  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::RegisterSdr.new()
  dm_robot.start
end
