require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'

module SdrIngest
  
  # +CompleteDeposit+ blah blah blah what does it do?   
  class CompleteDeposit < LyberCore::Robot
    
    def process_item(work_item)
      druid = work_item.druid
      result = Dor::WorkflowService.update_workflow_status("sdr", druid, "sdrIngestWF", "complete-deposit", "completed")
      if not result then
        raise "Update workflow \"complete-deposit\" failed"
      end
      
      update_provenance(druid, "deposit complete")
    end
    
    def update_provenance (druid, status)
      return true
    end
    
  end
  
end




# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::CompleteDeposit.new(
          'sdrIngest', 'complete-deposit')
  dm_robot.start
end
