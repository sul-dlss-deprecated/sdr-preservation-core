#!/usr/bin/env ruby
ENABLE_SOLR_UPDATES = false

require 'rubygems'
require 'lyber_core'

Dor::CREATE_WORKFLOW= true
#Dor::WF_URI = 'http://lyberservices-dev.stanford.edu:8080/workflow'
Dor::WF_URI = 'http://localhost:8080/workflow'

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

identityMetadata = <<-EOXML
  <identityMetadata objectId=#{pid}>
  <objectType>agreement</objectType>
  <objectId>druid:tx617qp8040</objectId>
  <otherId name='uuid'>c2e47ead-9ab8-4da8-b447-a30f0e097ddd</otherId>
  <sourceId source='sulair'>SULAIR_agreement_agreement</sourceId>
  <citationTitle>Agreement object for agreements</citationTitle>
  <citationCreator>DLSS staff</citationCreator>
  <agreementId>druid:tx617qp8040</agreementId>
  <tag>Agreements : Version 1</tag>
  </identityMetadata>
EOXML

Fedora::Repository.register('http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora')
obj = ActiveFedora::Base.new(:pid => pid, :label => 'sdr robot testing')

# Add the IdentityMetadataDS
identityMetadataDS = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"identityMetadata", :dsLabel=>"identityMetadata", :blob=>identityMetadata)
obj.add_datastream(identityMetadataDS)


obj.save

Dor::WorkflowService.create_workflow('dor', pid, 'googleScannedBookWF', xml)

puts 'Created dor object and workflow for ' << pid



