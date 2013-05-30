require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for completing the processing of each ingested object
  class CompleteDeposit < LyberCore::Robots::Robot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'complete-deposit'
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
      complete_deposit(work_item.druid)
      Dor::WorkflowService.update_workflow_status('dor', work_item.druid, 'accessionWF', 'sdr-ingest-received', 'completed')
    end

    # @param druid [String] The object identifier
    # @return [void] complete ingest of the item, update provenance, cleanup deposit data.
    def complete_deposit(druid)
      bag_pathname = DepositObject.new(druid).bag_pathname()
      repository = Stanford::StorageRepository.new
      new_version = repository.store_new_object_version(druid, bag_pathname)
      result = new_version.verify_version_storage
      if result.verified == false
        LyberCore::Log.info result.to_json(verbose=false)
        raise LyberCore::Exceptions::ItemError.new(druid, "Failed verification",e)
      end
      update_provenance(druid)
      bag_pathname.rmtree
    end

    # @param druid [String] The object identifier
    # @return [ActiveFedora::Datastream] Update_provenance by doing:
    #   * Create SDR provenance that includes steps in the sdrIngestWorkflow as an XML string
    #   * Retrieve the object's existing provenance data stored in Sedora
    #   * Append SDR provenance to the existing provenance data
    #   * Update the object's Sedora provenance datastream
    def update_provenance(druid)
      sedora_object = Sdr::SedoraObject.find(druid)
      #workflow_datastream = sedora_object.sdrIngestWF
      workflow_datastream_content = Dor::WorkflowService.get_workflow_xml('sdr',druid, 'sdrIngestWF')
      provenance_datastream = sedora_object.provenanceMetadata
      sdr_agent = create_sdr_agent(druid, workflow_datastream_content)
      full_provenance = append_sdr_agent(druid, sdr_agent.to_xml, provenance_datastream.content)
      provenance_datastream.content = full_provenance.to_xml(:indent=>2)
      provenance_datastream.save
      provenance_datastream
    rescue ActiveFedora::ObjectNotFoundError => e
      raise LyberCore::Exceptions::FatalError.new("Cannot find object #{druid}",e)
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot update provenanceMetadata datastream for #{druid}",e)
    end

    # @param druid [String] The object identifier
    # @param workflow_datastream_content [String] The content of the 'workflow' datastream
    # @return [Nokogiri::XML::DocumentFragment] create SDR provenance XML stanza by doing:
    #   * Create a Nokogiri XML DocumentFragment
    #   * Add child "agent" and grandchild "what"
    #   * Build "events" from events with 'completed' status in the sdrIngestWorkflow
    #   * Add events as child of "what"
    #   * Return the XML DocumentFragment
    def create_sdr_agent(druid, workflow_datastream_content)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter create_sdr_provenance")
      # Create the "agent" for SDR
      sdr_agent = Nokogiri::XML::fragment "<agent/>"

      agent = sdr_agent.child
      agent['name'] = 'SDR'

      # Create the "what" for this obj
      what = Nokogiri::XML::Node.new 'what', sdr_agent
      agent.add_child(what)
      what['object'] = druid

      worflow_xml_doc = Nokogiri::XML.parse(workflow_datastream_content)
      processes = worflow_xml_doc.xpath(".//process")
      processes.each do |process|
        pname = process['name']
        LyberCore::Log.debug("Process name is : #{pname}")
        if (process['status'].eql?('completed')) then
          event = Nokogiri::XML::Node.new 'event', sdr_agent
          event['who'] = 'SDR-robot:' + pname
          event['when'] = process['datetime']
          what.add_child(event)

          case pname
            when "register-sdr"
              event.content = "#{druid} has been registered in Sedora"
            when "transfer-object"
              event.content = "#{druid} has been transferred"
            when "validate-bag"
              event.content = "#{druid} has been validated"
            when "populate-metadata"
              event.content = "Metadata for #{druid} has been populated in Sedora"
            when "verify-agreement"
              event.content = "Agreement for #{druid} exists in Sedora"
          end
          LyberCore::Log.debug("Event content is : #{event.content}")
        end
      end

      LyberCore::Log.debug("sdr_prov stanza is : #{sdr_agent.to_xml}")
      sdr_agent
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot create sdr_prov stanza xml for #{druid}",e)

    end

    # @param druid [String] The object identifier
    # @param sdr_provenance [Nokogiri::XML::DocumentFragment]
    # @param dor_provenance [String]
    # @return [Nokogiri::XML::Document] Return the merged provenanceMetadata by doing:
    #   * Parse the DOR provenance data or create a new document
    #   * append the SDR provenance
    #   * reformat the XML to eliminate whitespace
    def append_sdr_agent(druid, sdr_provenance, dor_provenance)
      if (dor_provenance.nil? or dor_provenance.empty?) then
        full_provenance = Nokogiri::XML "<provenanceMetadata objectId='#{druid}'/>"
      else
        full_provenance = Nokogiri::XML(dor_provenance)
      end

      # Add sdr_prov to provenanceMetadata as a child node
      sdr_xml_fragment = Nokogiri::XML.fragment(sdr_provenance)
      full_provenance.root.add_child(sdr_xml_fragment)

      LyberCore::Log.debug("Created sdr_prov as a child node in provenanceMetadata")
      # Reformat the output to regularize the whitespace between elements (pretty print)
      Nokogiri::XML(full_provenance.to_xml) do |config|
        config.noblanks
      end
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Cannot create new provenanceMetadata xml for #{druid}",e)
    end

    def verification_queries(druid)
      user_password = "#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}"
      fedora_url = Sdr::Config.sedora.url.sub('//',"//#{user_password}@")
      storage_url = Sdr::Config.sdr_storage_url
      workflow_url = Dor::Config.workflow.url
      queries = []
      queries << [
          "#{fedora_url}/objects/#{druid}/datastreams/provenanceMetadata/content?format=xml",
          200, /<agent name="SDR">/ ]
      queries << [
          "#{storage_url}/objects/#{druid}",
          200, /<html>/ ]
      queries << [
          "#{workflow_url}/sdr/objects/#{druid}/workflows/sdrIngestWF",
          200, /completed/ ]
      queries
    end

    def verification_files(druid)
      repository = Stanford::StorageRepository.new
      files = []
      files << repository.storage_object_pathname(druid).to_s
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::CompleteDeposit.new()
  dm_robot.start
end
