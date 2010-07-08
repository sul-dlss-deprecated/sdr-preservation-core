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

    # Override the robot LyberCore::Robot.process_item method.
    # - Finds the object's agreement object in DOR

    def process_item(work_item)

      # Identifiers
      druid = work_item.druid
      puts "Druid being processed is " + druid 

      # get the agreement id for this object

      get_agreement_id(druid)

      puts @agreement_id

      # check if it is in sedora
      puts "SEDORA_URI is " + SEDORA_URI
      LyberCore::Connection.get("http://fedoraAdmin:fedoraAdmin@sdr-fedora-dev.stanford.edu:80/fedora/objects/" + "#{@agreement_id}", {})
      #LyberCore::Connection.get(SEDORA_URI + "/objects/" + agreementId, {})

      # If agreement object is not in Sedora then throw an exception
      
    end

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
      @agreement_id = doc.xpath("//agreementId/text()")
    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::VerifyAgreement.new('sdrIngest', 'verify-agreement')
  dm_robot.start
end
