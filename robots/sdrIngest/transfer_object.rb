#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'

# +Deposit+ initializes the SdrIngest workflow by registering the object and transferring 
# the object from DOR to SDR's staging area.
#
# The most up to date description of the deposit workflow is always in config/workflows/deposit/depositWorkflow.xml. 
# (Content included below.)
# :include:config/workflows/deposit/depositWorkflow.xml

module SdrIngest

# Transfers objects from DOR workspace to SDR's staging area.  
# - notifies DOR of success by: <b><i>need to be filled in</i></b>
# - notifies DOR of missing object by: <i><b>need to be filled in</b></i>

  class TransferObject < LyberCore::Robot

    # Override the robot LyberCore::Robot.process_item method.
    # * Makes use of the Robot Framework FileUtilities.
    def process_item(work_item)
      # Identifiers

      druid = work_item.druid
      return FileUtilities.transfer_object(druid, DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR)
      
    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::TransferObject.new(
          'sdrIngest', 'transfer-object')
  dm_robot.start
end
