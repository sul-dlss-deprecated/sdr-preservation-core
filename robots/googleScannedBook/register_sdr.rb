#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'dor_service'
require 'lyber_core'
require 'active-fedora'




module GoogleScannedBook

# Creates +Sedora+ objects and bootstrapping the workflow.
  class RegisterSdr < LyberCore::Robot

    # Override the robot LyberCore::Robot.process_item method.
    # - Creates a *Sedora* object
    # - Initializes the +Deposit+ workflow
    def process_item(work_item)

      Fedora::Repository.register(SEDORA_URI)

      # Identifiers

      druid = work_item.druid

      obj = ActiveFedora::Base.new(:pid => druid)
      obj.save

      workflow_xml = File.open(File.join(File.dirname(__FILE__), "..", "..", "config", "workflows", "sdrIngest", 'sdrIngestWorkflow.xml'), 'rb') { |f| f.read }
      
      Dor::WorkflowService.create_workflow('sdr', druid, 'sdrIngestWF', workflow_xml)
      
    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = GoogleScannedBook::RegisterSdr.new(
          'googleScannedBook', 'register-sdr')
  dm_robot.start
end

