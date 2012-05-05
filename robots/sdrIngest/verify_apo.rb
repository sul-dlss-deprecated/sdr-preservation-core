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
require 'pathname'


module SdrIngest

  # Verifies that an APO object exists for an object
  class VerifyApo

    # The set of valid APO IDs already encountered in this session
    @@valid_apo_ids = Array.new

    def self.valid_apo_ids
      @@valid_apo_ids
    end

    # Lookup the identifier of the APO object and verify that it has previously been ingested
    def self.get_apo_druid(relationship_md_pathname)
      pathname=Pathname.new(relationship_md_pathname)
      doc = Nokogiri::XML(pathname.read)
      apo_node=doc.xpath("//hydra:isGovernedBy",'hydra'=>'http://projecthydra.org/ns/relations#').first
      apo_id=apo_node.attribute_with_ns('resource','http://www.w3.org/1999/02/22-rdf-syntax-ns#')
      apo_druid = Pathname.new(apo_id).basename.to_s
    end

    # Lookup the identifier of the APO object and verify that it has previously been ingested
    def self.verify_apo_in_fedora(druid, fedora_uri)
      # check if it is in sedora
      if @@valid_apo_ids.include?(druid)
        return true
      else
        begin
          apo_uri_string = "#{fedora_uri}/objects/#{druid}"
          LyberCore::Connection.get(apo_uri_string, {})
          @@valid_apo_ids << druid
          return true
        rescue Net::HTTPServerException => e
          # If APO object is not in Sedora then throw an exception
          raise LyberCore::Exceptions::FatalError.new("Couldn't find apo object #{druid} in Fedora",e)
        rescue Exception => e
          raise LyberCore::Exceptions::FatalError.new("Connecting to #{fedora_uri} in verify-apo fails", e)
        end
      end
    end

  end
end
