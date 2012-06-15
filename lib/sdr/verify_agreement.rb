require File.join(File.dirname(__FILE__), 'libdir')
require 'boot'

module Sdr

  # Verifies that an agreement object exists for each object
  class VerifyAgreement < LyberCore::Robots::Robot

    # the agreement_id of the current workitem
    attr_reader :valid_identifiers

    def initialize()
      super('sdrIngestWF', 'verify-agreement',
        :logfile => "#{Sdr::Config.logdir}/verify-agreement.log",
        :loglevel => Logger::INFO,
        :options => ARGV[0])
      @valid_identifiers = Array.new()
      env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{env}")
      LyberCore::Log.debug("Process ID is : #{$$}")
    end
  
    # Lookup the identifier of the agreement object and verify that it has previously been ingested
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      verify_agreement(work_item.druid)
    end

    def verify_agreement(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter validate_agreement")
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

    # Lookup the identifier of the APO object and verify that it has previously been ingested
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

    # @return [Nokogiri::XML::NodeSet] Given a druid, get its identityMetadata datastream from Sedora
    #   and extract the agreement_id in a NodeSet.  If not found, return empty NodeSet.
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

    def get_metadata(druid, dsid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter get_metadata")
      pathname = SdrDeposit.bag_pathname(druid).join("data/metadata/#{dsid}.xml")
      if pathname.exist?
        pathname.read
      else
        nil
      end
    end


    # check if the itentifier is a sedora pid
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

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::VerifyAgreement.new()
  dm_robot.start
end
