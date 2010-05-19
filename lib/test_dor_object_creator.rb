#!/usr/bin/env ruby
ENABLE_SOLR_UPDATES = false

require 'rubygems'
require 'lyber_core'

Dor::CREATE_WORKFLOW= true
Dor::WF_URI = 'http://lyberservices-dev.stanford.edu:8080/workflow'

xml = <<-EOXML
<workflow id="googleScannedBookWF">
	 <process name="ingest-deposit" status="completed"/>
   <process name="register-sdr" status="waiting"/>
</workflow>
EOXML

if(ARGV.size != 1)
  puts 'You must provide a pid'
  exit
end

pid = ARGV[0]

Fedora::Repository.register('http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora')
obj = ActiveFedora::Base.new(:pid => pid, :label => 'sdr robot testing')
obj.save

Dor::WorkflowService.create_workflow('dor', pid, 'googleScannedBookWF', xml)

puts 'Created dor object and workflow for ' << pid



