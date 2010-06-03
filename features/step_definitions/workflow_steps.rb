require 'net/http'
require 'nokogiri'
require 'open-uri'
# require '../support/workflow_helpers.rb'

WORKFLOW_SERVICE_URL = "http://lyberservices-dev.stanford.edu:8080/workflow"
DOR_DEV_FEDORA_URL = "http://dor-dev.stanford.edu/fedora/"
testpid ||= Nokogiri::XML(open(DOR_DEV_FEDORA_URL << "/management/getNextPID?xml=true&namespace=sdrtwo", {:http_basic_authentication=>["fedoraAdmin", "fedoraAdmin"]})).xpath("//pid").text


# This is a dummy test. It just helps the cucumber read more easily. 
When /^I want to test the sedora ingest workflow$/ do
  true
end


# Can I get to the WORKFLOW_SERVICE_URL without raising an exception
Then /^I should be able to talk to the workflow service$/ do
  lambda { Net::HTTP.get_response(URI.parse(WORKFLOW_SERVICE_URL))}.should_not raise_exception()
  # TODO: Do I get a 200 response code?
end

# This is a re-write of the test_dor_object_creator script that Willy wrote
Then /^I should be able to create a new object in DOR for testing against$/ do

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

  Fedora::Repository.register('http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora')
  obj = ActiveFedora::Base.new(:pid => testpid, :label => 'sdr robot testing')
  obj.save
  Dor::WorkflowService.create_workflow('dor', testpid, 'googleScannedBookWF', xml)
  
  # our new PID should be in the sdrtwo namespace
  obj.pid.should include("sdrtwo")
end

