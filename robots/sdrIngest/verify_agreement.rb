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
#require 'logger'
require 'English'


module SdrIngest


  # Verifies preservation agreement for objects
  class VerifyAgreement < LyberCore::Robots::Robot

    # the agreement_id of the current workitem
    attr_reader :agreement_id 
    attr_reader :env
    
    # Override the LyberCore::Robot initialize method so we can set object attributes during initialization
    def initialize()
      super('sdrIngestWF', 'verify-agreement',
        :logfile => '/tmp/verify-agreement.log', 
        :loglevel => Logger::INFO,
        :options => ARGV[0])

      @env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{@env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
      puts DOR_URI
    end
  

    # Extract the druid and pass it along to process_druid
    # This allows the robot to accept either a work_item or a druid
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      druid = work_item.druid
      process_druid(druid)
    end

    # Finds the object's agreement object in DOR
    def process_druid(druid)

      LyberCore::Log.debug("Druid being processed is #{druid}")
      puts "Druid being processed is " + druid 

      # get the agreement id for this object
      @agreement_id ||= get_agreement_id(druid)
      #puts "Agreement id is #{@agreement_id}"
      LyberCore::Log.debug("Agreement id is #{@agreement_id}")

      # check if it is in sedora
      LyberCore::Log.debug( "SEDORA_URI is " + SEDORA_URI)
      begin
        #LyberCore::Connection.get("http://fedoraAdmin:fedoraAdmin@sedora-test.stanford.edu/fedora/objects/" + "#{@agreement_id}", {})
        #LyberCore::Connection.get("http://sedora-test.stanford.edu/fedora/objects/" + "#{@agreement_id}", {})
        
        LyberCore::Connection.get(SEDORA_URI + "/objects/" +"#{@agreement_id}", {})
        LyberCore::Log.debug("Agreement is available in Sedora at http://sedora-test.stanford.edu/fedora/objects/" + "#{@agreement_id}")
      rescue Net::HTTPServerException
        # If agreement object is not in Sedora then throw an exception
        raise "Couldn't find agreement object #{@agreement_id} in Sedora"
      rescue
        raise "Connecting to SEDORA in verify-agreement fails"
      end
    end

    # Given a druid, get its IDENTITY metadata datastream from Sedora and 
    # extract the agreement_id
    def get_agreement_id(druid)
      
      #puts "In get_agreement_id "
      # Declare resp outside of the http.start loop so it will be available after the loop ends
      resp = ""

      http = Net::HTTP.new("sedora-test.stanford.edu", 443)
      http.use_ssl = true
      http.start do |http|
         req = Net::HTTP::Get.new("/fedora/objects/#{druid}/datastreams/IDENTITY/content", {"User-Agent" =>
                                   "RubyLicious 0.2"})
         req.basic_auth(SEDORA_USER, SEDORA_PASS)
         response = http.request(req)
         resp = response.body
      end
      doc = Nokogiri::XML(resp)
      LyberCore::Log.debug(doc.xpath("//agreementId/text()") )
      doc.xpath("//agreementId/text()")
    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::VerifyAgreement.new()
  # If this robot is invoked with a specific druid, it will run for that druid only
  if(ARGV[0])
    puts "Verifying agreement for #{ARGV[0]}"
    dm_robot.process_druid(ARGV[0])
  else
    dm_robot.start
  end
end
