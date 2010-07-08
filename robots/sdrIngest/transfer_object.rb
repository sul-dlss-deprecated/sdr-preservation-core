#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'

module SdrIngest

# +TransferObject+ Transfers objects from DOR workspace to SDR's staging area.  
# - notifies DOR of success by: <b><i>need to be filled in</i></b>
# - notifies DOR of missing object by: <i><b>need to be filled in</b></i>

  class TransferObject < LyberCore::Robot
    
    # the destination object that gets created by running this script
    attr_reader :dest_path

    # Override the robot LyberCore::Robot.process_item method.
    # * Makes use of the Robot Framework FileUtilities.
    def process_item(work_item)
      # Identifiers
      druid = work_item.druid
      @dest_path = File.join(SDR_DEPOSIT_DIR,druid)
      if File.exists?(@dest_path)
        raise "Object already exists: #{@dest_path}"
      else
        return FileUtilities.transfer_object(druid, DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR)
      end
    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::TransferObject.new(
          'sdrIngest', 'transfer-object')
  dm_robot.start
end
