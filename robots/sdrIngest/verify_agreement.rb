#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'dor_service'
require 'lyber_core'
require 'active-fedora'


module Deposit

# putting this code in a class method makes it easier to test
  class VerifyAgreement < LyberCore::Robot

    def process_item(work_item)

      # Identifiers

      druid = work_item.druid

      # get the agreement id for this object

      agreement_id = work_item.identityMetadata.agreementId
      # check if it is in sedora
      
      # testing for now
      LyberCore::Connection.get("http://sdr-fedora-dev.stanford.edu/fedora/objects/" + agreementId, {})
      
    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Deposit::RegisterSdr.new(
          'sdrIngest', 'verify-agreement', :druid_ref => ARGV[0])
  dm_robot.start
end

