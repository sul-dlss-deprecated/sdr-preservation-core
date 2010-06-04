#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'bagit'

module SdrIngest

  # Validates the Bag that has been transferring in SDR's staging area
  class ValidateBag < LyberCore::Robot

    # Override the robot LyberCore::Robot.process_item method.
    # * Makes use of the Robot Framework FileUtilities.
    def process_item(work_item)
      # Identifiers

      druid = work_item.druid
      dest_path = File.join(SDR_DEPOSIT_DIR,druid)
      bag = BagIt::Bag.new dest_path
      if not bag.valid?
        raise "bag not valid: #{dest_path}"
      end
      
      return nil

    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::ValidateBag.new(
          'sdrIngest', 'validate-bag')
  dm_robot.start
end
