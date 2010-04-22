#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'dor_service'
require 'lyber_core'
require 'active-fedora'




module Deposit

# putting this code in a class method makes it easier to test
  class RegisterSdr < LyberCore::Robot

    def process_item(work_item)

      Fedora::Repository.register(SEDORA_URI)

      # Identifiers

      druid = work_item.druid

      obj = ActiveFedora::Base.new(:pid => druid)
      obj.save

      workflow_xml = File.join(File.join(File.dirname(__FILE__), "..", "..", "config", "workflows", "deposit", 'depositWorkflow.xml'))
      Dor::WorkflowService.create_workflow(druid, 'depositWF', workflow_xml)
      
      work_item.set_success
    rescue Exception => e
      work_item.set_error(e)

    end
  end
end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Deposit::RegisterSdr.new(
          'deposit', 'register-sdr', :druid_ref => ARGV[0])
  dm_robot.start
end

