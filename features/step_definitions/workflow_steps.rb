require 'rubygems'
require 'lyber_core'
require 'net/http'
require 'nokogiri'
require 'open-uri'
require 'fileutils'


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
           <process name="sdr-ingest-transfer" status="completed"/>
     <process name="sdr-ingest-deposit" status="waiting"/>
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
  puts "Checking for workflow at #{uri}"
  workflow_xml = Nokogiri::XML(open(uri))
  workflow_xml.xpath("//process[@name='#{step}'][@status='#{status}']").should_not be_empty

end

# ###################################################
# Run a robot. 
#
When /^I run the robot "([^"]*)" for the "([^"]*)" step of the "([^"]*)" workflow$/ do |robot, step, workflow|
  $:.unshift File.join(File.dirname(__FILE__), "../..", "lib")
  $:.unshift File.join(File.dirname(__FILE__), "../..", "robots")  
  
  ENV['ROBOT_ENVIRONMENT']='test'

  puts "running robot #{robot}"
  dm_robot = ""
  case robot
  when "SdrIngest::RegisterSdr"
    require 'sdrIngest/register_sdr'
    dm_robot = SdrIngest::RegisterSdr.new()
    dm_robot.process_items()
  when "SdrIngest::TransferObject"
    require 'sdrIngest/transfer_object'
    dm_robot = SdrIngest::TransferObject.new(workflow, step)
    FileUtils::mkdir_p(DOR_WORKSPACE_DIR)
    example_object = File.join(SDR2_EXAMPLE_OBJECTS, "druid:jc837rq9922")
    file_to_be_copied = File.join(DOR_WORKSPACE_DIR, testpid)
    FileUtils::cp_r(example_object, file_to_be_copied)
    dm_robot.start
  when "SdrIngest::ValidateBag"
    require 'sdrIngest/validate_bag'
    dm_robot = SdrIngest::ValidateBag.new(workflow, step)
    dm_robot.start
  when "SdrIngest::PopulateMetadata"
    require 'sdrIngest/populate_metadata'
    dm_robot = SdrIngest::PopulateMetadata.new(workflow, step)
    dm_robot.start
  when "SdrIngest::VerifyAgreement"
     require 'sdrIngest/verify_agreement'
     dm_robot = SdrIngest::VerifyAgreement.new(workflow, step)
     dm_robot.start
  when "SdrIngest::CompleteDeposit"
    require 'sdrIngest/complete_deposit'
    dm_robot = SdrIngest::CompleteDeposit.new(workflow, step)
    dm_robot.start
  end

end

# ###################################################

Then /^that object should exist in SEDORA$/ do
  uri = SEDORA_URI + '/get/' + testpid
  lambda { Net::HTTP.get_response(URI.parse(uri))}.should_not raise_exception()  
end

# ###################################################

Then /^it should have a SEDORA workflow datastream where "([^"]*)" is "([^"]*)"$/ do |name, status|
  # uri = SEDORA_URI + '/objects/' + testpid + '/datastreams/sdrIngestWF/content'
  # puts "uri = #{uri}"
  # lambda { Net::HTTP.get_response(URI.parse(uri))}.should_not raise_exception()
  require 'net/https'
  require "rexml/document"

  username = "fedoraAdmin"
  password = "fedoraAdmin"

  resp = href = "";
  begin
    http = Net::HTTP.new("sdr-fedora-dev.stanford.edu", 443)
    http.use_ssl = true
    http.start do |http|
      req = Net::HTTP::Get.new("/fedora/objects/#{testpid}/datastreams/sdrIngestWF/content", {"User-Agent" =>
          "RubyLicious 0.2"})
      req.basic_auth(username, password)
      response = http.request(req)
      resp = response.body
      puts resp
    end
    doc = Nokogiri::XML(resp)
    # puts doc.to_xml
    doc.xpath("//process[@name='#{name}']/@status").text.should eql(status)

  end

end

# ##################################################

Then /^there should be a properly named bagit object in SDR_DEPOSIT_DIR$/ do
  bagit_object = File.join(SDR_DEPOSIT_DIR, testpid)
  (File.exists? bagit_object).should == true
  (File.directory? bagit_object).should == true
end

# ##################################################

Then /^when I explicitly set "([^"]*)" to "([^"]*)"$/ do |step, status|
    Dor::WorkflowService.update_workflow_status("sdr", testpid, "sdrIngestWF", step, status)
end
