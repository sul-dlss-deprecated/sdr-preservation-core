#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'dor_service'
require 'lyber_core'
require 'active-fedora'




module Deposit

# Verifies preservation agreement for objects
  class VerifyAgreement < LyberCore::Robot


    # Override the robot LyberCore::Robot.process_item method.
    # - Finds the object's agreement object in DOR

    def process_item(work_item)

      # Identifiers

      druid = work_item.druid

      # testing for now
      LyberCore::Connection.get("http://sdr-fedora-dev.stanford.edu/fedora/objects/druid:456alpana", {})
      
    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Deposit::RegisterSdr.new(
          'deposit', 'verify-agreement', :druid_ref => ARGV[0])
  dm_robot.start
end

