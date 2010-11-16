#!/usr/bin/env ruby
# Xinlei Qiu
# xinlei@stanford.edu
# 13 May 2010

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'nokogiri'
require 'logger'

module SdrIngest
  
  # CompleteDeposit sends a callback message to DOR notifying the DOR
  # workflow that the sdrIngest workflow is complete
  class CompleteDeposit < LyberCore::Robots::Robot
    attr_reader :obj, :druid, :logg
    attr_writer :bag_directory
    
    # Workflow XML as read from the object 
    attr_reader :obj_wf 

    # Instance variable containing sdr provenance generated from the workflow datastream
    attr_reader :sdr_prov 

    # Existing provenance datastream, as read from the object
    attr_reader :obj_prov
       
    def initialize()
      super('sdrIngestWF', 'complete-deposit',
        :logfile => '/tmp/complete-deposit.log', 
        :loglevel => Logger::INFO,
        :options => ARGV[0])

      @env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
      
      @start_time = Time.new
      LyberCore::Log.debug("Start time is :   #{@start_time}")
            
      # by default, get the bags from the SDR_DEPOSIT_DIR
      # this can be explicitly changed if necessary
      @bag_directory = SDR_DEPOSIT_DIR
    end
    
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      
      @druid = work_item.druid
      raise "Cannot load Sedora object." unless get_fedora_object
      
      # Update provenance
      raise "Failed to update provenance to include Deposit completion." unless update_provenance

      # Update DOR workflow 
      result = Dor::WorkflowService.update_workflow_status("dor", @druid, "googleScannedBookWF", "sdr-ingest-deposit", "completed")
      raise "Update workflow \"complete-deposit\" failed." unless result
    end
    
    private
    # update_provenance 
    # * Creates SDR provenance that includes steps in the sdrIngestWorkflow as an XML string
    # * Retrieves the object's existing provenance data stored in Sedora
    # * Append SDR provenance to the existing provenance data
    # * Update the object's Sedora provenance datastream with SDR provenance attached    
    def update_provenance 
      create_sdr_provenance
      make_new_prov
      update_prov_datastream
    end
    
    # create_sdr_provenance
    # * Creates a Nokogiri XML DocumentFragment
    # * Adds child "agent" and grandchild "what"
    # * Builds "events" from events with 'completed' status in the sdrIngestWorkflow
    # * Adds events as child of "what"
    # * Saves the entire build up as an XML string in "sdr_prov"
    def create_sdr_provenance
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter create_sdr_provenance")
      # Create the "agent" for SDR
      doc_frag = Nokogiri::XML::DocumentFragment.parse <<-EOXML
            <agent>
            </agent>
            EOXML
      
      agent = doc_frag.child
      agent['name'] = 'SDR'
      
      # Create the "what" for this obj
      what = Nokogiri::XML::Node.new 'what', doc_frag
      what['object'] = @druid
      agent.add_child(what)

      # Get the events from the object, store it in "obj_wf" temporarily  
      @obj_wf = @obj.datastreams['sdrIngestWF'].content
      ingestWF = Nokogiri::XML.parse(self.obj_wf)

      processes = ingestWF.xpath(".//process")
      processes.each do |process|
        pstatus = process['status']
  
        if (pstatus.eql?('completed')) then
          pname = process['name']
          event = Nokogiri::XML::Node.new 'event', doc_frag
          event['who'] = 'SDR-robot:' + pname
          event['when'] = process['datetime']
          
          LyberCore::Log.debug("Process name is : #{pname}")
          
          case pname
            when "register-sdr"
              event.content = "Druid #{@druid} has been registered in Sedora"
            when "transfer-object"
              event.content = "Druid #{@druid} has been transfered"
            when "validate-bag"
              event.content = "Druid #{@druid} has been validated"
            when "populate-metadata"
              event.content = "Metadata for druid #{@druid} has been populated in Sedora"
            when "verify-agreement"
              event.content = "Agreement for druid #{@druid} exists in Sedora"
          end
          
          LyberCore::Log.debug("Event content is : #{event.content}")
          
          #event.content = pname
    
          what.add_child(event)
        end
      end
      
      # Put the results in "sdr_prov" so it can be tested
      @sdr_prov = doc_frag.to_s
      LyberCore::Log.debug("sdr_prov stanza is : #{@sdr_prov}")
      
    end
   
    # make_new_prov
    # * Retrieves provenance data from the Sedora object
    # * If there is existing provenance, 
    # ** append SDR provenance
    # ** otherwise, make SDR provenance the provenance
    # * Saves the end result as an XML string in "obj_prov"
    def make_new_prov
      # Retrieve existing provenance
      @obj_prov = @obj.datastreams['PROVENANCE'].content
      if (@obj_prov != nil && !@obj_prov.eql?('')) then
        ex_prov_frag = Nokogiri::XML @obj_prov 
      else
       ex_prov_frag = Nokogiri::XML <<-EOXML
        <provenanceMetadata objectId="#{@druid}">
        </provenanceMetadata>
        EOXML
      end
      ex_prov_node = ex_prov_frag.child

      # Add sdr_prov to provenanceMetadata as a child node
      sdr_prov_frag = Nokogiri::XML::DocumentFragment.parse @sdr_prov
      sdr_prov_node = sdr_prov_frag.child
      ex_prov_node.add_child(sdr_prov_node)
      
      @obj_prov = ex_prov_node.to_xml
      LyberCore::Log.debug("Created sdr_prov as a child node in provenanceMetadata")
    end
    
    def update_prov_datastream
      ds_id = 'PROVENANCE'
      ActiveFedora::Datastream.delete(@obj.pid, ds_id)
      ds = ActiveFedora::Datastream.new(:pid=>@obj.pid, :dsid=>ds_id, :dsLabel=>ds_id, :blob=>@obj_prov)
      @obj.add_datastream(ds)
      @obj.save
      LyberCore::Log.debug("Updated provenanceMetadata datastream")
    end
    
    # fetch the fedora object from the repository so we can attach datastreams to it
    # throw an error if we can't find the object
    def get_fedora_object
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter get_fedora_object")
      begin
        Fedora::Repository.register(SEDORA_URI)
        LyberCore::Log.debug("Registering #{SEDORA_URI}")
        
        @obj = ActiveFedora::Base.load_instance(@druid)
        LyberCore::Log.debug("Loaded druid #{@druid} into object #{@obj}")
        
      rescue Errno::ECONNREFUSED => e
        LyberCore::Log.fatal("Cannot connect to Fedora at url #{SEDORA_URI} : #{e.inspect}")
        LyberCore::Log.fatal( "#{e.backtrace.join("\n")}")
        
        raise RuntimeError, "Cannot connect to Fedora at url #{SEDORA_URI} : #{e}"  
        return nil     
      rescue
        return nil
      end
    end
  end
  
end


# This is the equivalent of a java main method
if __FILE__ == $0
  begin
    dm_robot = SdrIngest::CompleteDeposit.new()
    dm_robot.start
  rescue Exception => e
    puts "ERROR : " + e.message
    LyberCore::Log.error("Error in Complete Deposit :  #{e.message} + #{e.inspect}")
    LyberCore::Log.error("#{e.backtrace.join("\n")}")
  end
  puts "Complete Deposit done\n"
end
