WORKFLOW_SERVICE_URL = "http://lyberservices-dev.stanford.edu/workflow"

# This is a dummy test. It just helps the cucumber read more easily. 
When /^I want to test the sedora ingest workflow$/ do
  true
end


Then /^I should be able to talk to the workflow service$/ do
  require 'net/http'
  lambda { Net::HTTP.get_response(URI.parse(WORKFLOW_SERVICE_URL))}.should_not raise_exception()
end

When /^I create a new object$/ do
  
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




end
