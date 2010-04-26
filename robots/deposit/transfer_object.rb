#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'

module Deposit

# putting this code in a class method makes it easier to test
  class TransferObject < LyberCore::Robot

    def process_item(work_item)
      # Identifiers

      druid = work_item.druid
      FileUtilities.transfer_object(druid, DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR)
    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Deposit::TransferObject.new(
          'deposit', 'transfer-object')
  dm_robot.start
end