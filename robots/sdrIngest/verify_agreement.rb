#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

#require 'dor_service'
require 'dlss_service'
require 'lyber_core'
require 'active-fedora'
require 'net/https'
require "rexml/document"
require 'rubygems'
require 'nokogiri'
require 'logger'
require 'English'


module SdrIngest

  # Verifies preservation agreement for objects
  class VerifyAgreement < LyberCore::Robots::Robot

    # the agreement_id of the current workitem
    attr_reader :valid_agreement_ids
    attr_reader :env
    
    # Override the LyberCore::Robot initialize method so we can set object attributes during initialization
    def initialize()
      super('sdrIngestWF', 'verify-agreement',
        :logfile => "#{LOGDIR}/verify-agreement.log", 
        :loglevel => Logger::INFO,
        :options => ARGV[0])

      @env = ENV['ROBOT_ENVIRONMENT']
      @valid_agreement_ids = Array.new()
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
    end
  

    # Extract the druid and pass it along to process_druid
    # This allows the robot to accept either a work_item or a druid
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      druid = work_item.druid
      LyberCore::Log.debug("Druid being processed is #{druid}")

      # get the agreement id for this object
      agreement_id = get_agreement_id(druid)
      LyberCore::Log.debug("Agreement id is #{agreement_id}")

      # check if it is in sedora
      if @valid_agreement_ids.include?(agreement_id)
        return true
      else
        LyberCore::Log.debug( "SEDORA_URI is " + SEDORA_URI)
        begin
          agreement_uri_string = "#{SEDORA_URI}/objects/#{@agreement_id}"
          LyberCore::Log.debug("agreement_uri is : " + agreement_uri_string)
          LyberCore::Connection.get(agreement_uri_string, {})
          LyberCore::Log.debug("Agreement is available in Sedora at : " + agreement_uri_string)
          @valid_agreement_ids << agreement_id
          return true
        rescue Net::HTTPServerException => e
          # If agreement object is not in Sedora then throw an exception
          raise LyberCore::Exceptions::FatalError.new("Couldn't find agreement object #{@agreement_id} in Sedora",e)
        rescue Exception => e
          raise LyberCore::Exceptions::FatalError.new("Connecting to #{SEDORA_URI} in verify-agreement fails", e)
        end
      end
    end

    # Given a druid, get its IDENTITY metadata datastream from Sedora and 
    # extract the agreement_id
    def get_agreement_id(druid)
      
      LyberCore::Log.debug("In get_agreement_id ")
      begin
        # Declare resp outside of the http.start loop so it will be available after the loop ends
        resp = ""

        http = Net::HTTP.new("#{SEDORA_URI_BASE}", 443)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.start do |http|
           req = Net::HTTP::Get.new("/fedora/objects/#{druid}/datastreams/identityMetadata/content", {"User-Agent" =>
                                     "RubyLicious 0.2"})
           req.basic_auth(SEDORA_USER, SEDORA_PASS)
           response = http.request(req)
           resp = response.body
        end
        doc = Nokogiri::XML(resp)
        LyberCore::Log.debug(doc.xpath("//agreementId/text()") )
        doc.xpath("//agreementId/text()")
      rescue Exception => e
        raise LyberCore::Exceptions::FatalError.new("Could not get an agreement for #{druid} from #{SEDORA_URI}", e)
      end
    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::VerifyAgreement.new()
  dm_robot.start
end
