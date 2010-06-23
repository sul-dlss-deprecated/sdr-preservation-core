require 'rubygems'
require 'lyber_core'
require 'net/http'
require 'nokogiri'
require 'open-uri'

# if you need to run these tests from a machine that can't connect to lyberservices-dev
# use ssh port forwarding like this:
# 1. ssh -L 8080:localhost:8080 lyberadmin@lyberservices-dev.stanford.edu
# 2. replace the value of WORKFLOW_SERVICE_URL with "http://localhost:8080/workflow"
WORKFLOW_SERVICE_URL = "http://lyberservices-dev.stanford.edu/workflow"
# WORKFLOW_SERVICE_URL = "http://localhost:8080/workflow"
DOR_DEV_FEDORA_URL = "http://dor-dev.stanford.edu/fedora/"
ENABLE_SOLR_UPDATES = false


# At the start of the process, get a new pid
testpid ||= Nokogiri::XML(open(DOR_DEV_FEDORA_URL << "/management/getNextPID?xml=true&namespace=sdrtwo", {:http_basic_authentication=>["fedoraAdmin", "fedoraAdmin"]})).xpath("//pid").text

# ###################################################
#
# This is a dummy test. It just helps the cucumber features read more easily. 
# 
When /^I want to test the sedora ingest workflow$/ do
  true
end

# ###################################################
#
# Can I get to the WORKFLOW_SERVICE_URL without raising an exception?
# Do I get a 200 response code or something else? 
#
Then /^I should be able to talk to the workflow service$/ do
  lambda { Net::HTTP.get_response(URI.parse(WORKFLOW_SERVICE_URL))}.should_not raise_exception()
  # TODO: Do I get a 200 response code?
end

# ###################################################
# 
# This is a re-write of the test_dor_object_creator script that Willy wrote
# 
Then /^I should be able to create a new object in DOR for testing against$/ do

 ENABLE_SOLR_UPDATES = false

  Dor::CREATE_WORKFLOW= true
  Dor::WF_URI = WORKFLOW_SERVICE_URL

  xml = <<-EOXML
  <workflow id="googleScannedBookWF">
           <process name="ingest-deposit" status="completed"/>
     <process name="register-sdr" status="waiting"/>
  </workflow>
  EOXML

  Fedora::Repository.register("http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora/")
  puts "testpid = #{testpid}"
  obj = ActiveFedora::Base.new(:pid => testpid, :label => 'sdr robot testing')
  obj.save
  Dor::WorkflowService.create_workflow('dor', testpid, 'googleScannedBookWF', xml)
  
  # our new PID should be in the sdrtwo namespace
  obj.pid.should include("sdrtwo")
end

# ###################################################
# Check the workflow datastreams:
# 1. Do they exist?
# 2. Are they in the expected state? 
#
Then /^that object should have a "([^\"]*)" state where "([^\"]*)" is "([^\"]*)"$/ do |workflow, step, status|
  
  uri = WORKFLOW_SERVICE_URL + "/dor/objects/" + testpid + "/workflows/" + workflow
  # puts "Checking for workflow at #{uri}"
  workflow_xml = Nokogiri::XML(open(uri))
  workflow_xml.xpath("//process[@name='#{step}'][@status='#{status}']").should_not be_empty

end

# ###################################################
# Run a robot. Assume robots are in robots/wf_name/robot_name.rb
#
When /^I run the robot "([^\"]*)":"([^\"]*)"$/ do |wf_name, robot_name|
  $:.unshift File.join(File.dirname(__FILE__), "../..", "lib")
  $:.unshift File.join(File.dirname(__FILE__), "../..", "robots")
  require 'googleScannedBook/register_sdr'
  
  ENV['ROBOT_ENVIRONMENT']='test'

  dm_robot = GoogleScannedBook::RegisterSdr.new('googleScannedBook', 'register-sdr')
  dm_robot.start  
end

# ###################################################

Then /^that object should exist in SEDORA$/ do
  uri = SEDORA_URI << '/get/' << testpid
  lambda { Net::HTTP.get_response(URI.parse(uri))}.should_not raise_exception()  
end

