require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # Robot for verifying that an APO or agreement object exists for each object
  class VerifyAgreement < LyberCore::Robots::Robot

    # A cache of APO/agreement object identifiers that have already been verified to exist in Sedora
    attr_reader :valid_identifiers

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'verify-agreement'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
      @valid_identifiers = Array.new()
    end
  
    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      verify_agreement(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [Boolean] Find the APO or Agreement identifier in the object metadata,
    #   and verify that the identifer belongs to a previously ingested object
    def verify_agreement(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter verify_agreement")
      LyberCore::Log.debug("Druid being processed is #{druid}")
      if apo_id = find_apo_id(druid) and verify_identifier(apo_id)
        LyberCore::Log.debug("APO id #{apo_id} was verified")
        true
      elsif agreement_id = find_agreement_id(druid) and verify_identifier(agreement_id)
        LyberCore::Log.debug("Agreement id #{agreement_id} was verified")
        true
      else
        raise LyberCore::Exceptions::ItemError.new(druid,
           "Neither APO ID (#{apo_id.to_s}) or Agreement ID (#{agreement_id.to_s}) could be verified")
      end
    end

    # @param druid [String] The object identifier
    # @return [String] The 'isGovernedBy' APO identifier found in the relationshipMetadata
    def find_apo_id(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter find_apo_id")
      if (relationship_metadata = get_metadata(druid,'relationshipMetadata'))
        doc = Nokogiri::XML(relationship_metadata)
        nodeset = doc.xpath("//hydra:isGovernedBy",'hydra'=>'http://projecthydra.org/ns/relations#')
        return nil if nodeset.empty?
        apo_id = nodeset.first.attribute_with_ns('resource','http://www.w3.org/1999/02/22-rdf-syntax-ns#')
        apo_id.text.split('/')[-1]
      else
        nil
      end
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Unable to find APO id for #{druid}", e)
    end

    # @param druid [String] The object identifier
    # @return [String] The agreement identifier found in the identityMetadata datastream
    def find_agreement_id(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter find_agreement_id")
      if (identity_metadata = get_metadata(druid,'identityMetadata'))
        doc = Nokogiri::XML(identity_metadata)
        nodeset= doc.xpath("//agreementId/text()")
        return nil if nodeset.empty?
        nodeset.first.text
      else
        nil
      end
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Unable to find agreement id for #{druid}", e)
    end

    # @param druid [String] The object identifier
    # @param dsid [String] The datastream identifier, which is also the basename of the XML data file
    # @return [String] The contents of the specified datastream, else nil if not found
    def get_metadata(druid, dsid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter get_metadata")
      sedora_object = Sdr::SedoraObject.find(druid)
      datastream = sedora_object.datastreams[dsid]
      if datastream.new?
        nil
      else
        datastream.content
      end
      #pathname = SdrDeposit.bag_pathname(druid).join("data/metadata/#{dsid}.xml")
      #if pathname.exist?
      #  pathname.read
      #else
      #  nil
      #end
    end

    # @param identifier [String] The APO or agreement identifier
    # @return [Boolean] Return true if the identifier is a sedora pid
    def verify_identifier(identifier)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter verify_identifier")
      if @valid_identifiers.include?(identifier)
        true
      elsif SedoraObject.exists?(identifier)
        @valid_identifiers << identifier
        true
      else
        false
      end
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("unable to verify identifier", e)
    end

    def verification_queries(druid)
      queries = []
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
  dm_robot = Sdr::VerifyAgreement.new()
  dm_robot.start
end
