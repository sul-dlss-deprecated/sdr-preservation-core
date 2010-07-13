#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'dor_service'
require 'lyber_core'
require 'active-fedora'
require 'net/https'
require "rexml/document"
require 'rubygems'
require 'nokogiri'

module SdrIngest


  # Verifies preservation agreement for objects
  class VerifyAgreement < LyberCore::Robot

    # the agreement_id of the current workitem
    attr_reader :agreement_id 

    # Extract the druid and pass it along to process_druid
    # This allows the robot to accept either a work_item or a druid
    def process_item(work_item)
      druid = work_item.druid
      process_druid(druid)
    end

    # Finds the object's agreement object in DOR
    def process_druid(druid)

      puts "Druid being processed is " + druid 

      # get the agreement id for this object
      @agreement_id ||= get_agreement_id(druid)

      # check if it is in sedora
      puts "SEDORA_URI is " + SEDORA_URI
      begin
        LyberCore::Connection.get("http://fedoraAdmin:fedoraAdmin@sdr-fedora-dev.stanford.edu:80/fedora/objects/" + "#{@agreement_id}", {})
      #LyberCore::Connection.get(SEDORA_URI + "/objects/" + agreementId, {})
      rescue Net::HTTPServerException
        # If agreement object is not in Sedora then throw an exception
        raise "Couldn't find agreement object #{@agreement_id} in sedora"
      rescue
        raise "Something went wrong."
      end
    end

    # Given a druid, get its IDENTITY metadata datastream from Sedora and 
    # extract the agreement_id
    def get_agreement_id(druid)

      # Declare resp outside of the http.start loop so it will be available after the loop ends
      resp = ""

      http = Net::HTTP.new("sdr-fedora-dev.stanford.edu", 443)
      http.use_ssl = true
      http.start do |http|
         req = Net::HTTP::Get.new("/fedora/objects/#{druid}/datastreams/IDENTITY/content", {"User-Agent" =>
                                   "RubyLicious 0.2"})
         req.basic_auth(SEDORA_USER, SEDORA_PASS)
         response = http.request(req)
         resp = response.body
      end
      doc = Nokogiri::XML(resp)
      puts doc.xpath("//agreementId/text()") 
      doc.xpath("//agreementId/text()")
    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::VerifyAgreement.new('sdrIngest', 'verify-agreement')
  # If this robot is invoked with a specific druid, it will run for that druid only
  if(ARGV[0])
    puts "Verifying agreement for #{ARGV[0]}"
    dm_robot.process_druid(ARGV[0])
  else
    dm_robot.start
  end
end
