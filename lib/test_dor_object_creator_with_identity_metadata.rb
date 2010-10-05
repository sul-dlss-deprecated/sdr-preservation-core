#!/usr/bin/env ruby
ENABLE_SOLR_UPDATES = false

require 'rubygems'
require 'lyber_core'

Dor::CREATE_WORKFLOW= true
#Dor::WF_URI = 'http://lyberservices-dev.stanford.edu:8080/workflow'
Dor::WF_URI = 'http://localhost:8080/workflow'

xml = <<-EOXML
<workflow id="googleScannedBookWF">
   <process name="sdr-ingest-transfer" status="completed"/>
   <process name="sdr-ingest-deposit" status="waiting"/>
</workflow>
EOXML


if(ARGV.size != 1)
  puts 'You must provide a PID'
  exit
end

PID = ARGV[0]

identityMetadata = <<-EOXML
  <identityMetadata objectId="#{PID}">
  <objectType>item</objectType>
  <objectId>#{PID}</objectId>
  <objectLabel>Google Scanned Book, barcode 36105005666438</objectLabel>
  <objectCreator>DOR</objectCreator>
  <citationTitle>Encyclopedia of comedy: for professional entertainers,
        social clubs, comedians, lodges and all who are in search of humorous
        literature</citationTitle>
  <citationCreator>Janson, James Melville.</citationCreator>
  <sourceId source="google">STANFORD_36105005666438</sourceId>
  <otherId name="shelfseq">PN 006161 .J32 1899</otherId>
  <otherId name="catkey">2387909</otherId>
  <otherId name="barcode">36105005666438</otherId>
  <otherId name="callseq">1</otherId>
  <otherId name="uuid">a47a524e-e2b9-4049-b31f-336647577122</otherId>
  <agreementId>druid:zn292gq7284</agreementId>
  <tag>Google Book : Scan source STANFORD</tag>
  <tag>Book : US pre-1923</tag>
  <tag>Google Book : GBS : VIEW_FULL</tag>
  </identityMetadata>

EOXML

Fedora::Repository.register('http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora')

# Make sure we're starting with a blank object
  begin
     obj = ActiveFedora::Base.load_instance(PID)
     obj.delete
  rescue
     $stderr.print $!
  end

# Create a new object
obj = ActiveFedora::Base.new(:pid => PID, :label => 'sdr robot testing')

# Add the IdentityMetadataDS
identityMetadataDS = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"identityMetadata", :dsLabel=>"identityMetadata", :blob=>identityMetadata)
obj.add_datastream(identityMetadataDS)
obj.save

Dor::WorkflowService.create_workflow('dor', PID, 'googleScannedBookWF', xml)

puts 'Created dor object and workflow for ' << PID
