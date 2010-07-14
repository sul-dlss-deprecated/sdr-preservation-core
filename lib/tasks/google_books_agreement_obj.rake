require 'lyber_core'

namespace :objects do
  
  PID = "druid:zn292gq7284"
  
  rels_ext = <<-EOXML
  <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
  <rdf:Description rdf:about='info:fedora/druid:zn292gq7284'>
  <fedora-model:hasModel xmlns:fedora-model='info:fedora/fedora-system:def/model#' rdf:resource='info:fedora/dor:agreement'/>
  </rdf:Description>
  </rdf:RDF>
  EOXML
  
  identityMetadata = <<-EOXML
  <identityMetadata objectId='druid:zn292gq7284'>
  <objectType>agreement</objectType>
  <objectAdminClass>Agreement</objectAdminClass>
  <objectLabel>Agreement object for GoogleBooks</objectLabel>
  <objectCreator>DOR</objectCreator>
  <citationTitle>Agreement object for GoogleBooks</citationTitle>
  <citationCreator>DLSS staff</citationCreator>
  <otherId name="uuid">0a5690af-73ec-415e-aab7-6e2d3bd490a9</otherId>
  <sourceId source="sulair">SULAIR_deposit_agreement</sourceId>
  <agreementId>druid:tx617qp8040</agreementId>
  <tag>Agreements : Version 1</tag>
  </identityMetadata>
  EOXML
  
  DC = <<-EOXML

<oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
  <dc:title>SDR Deposit agreement for Google Scanned Books</dc:title>
  <dc:identifier>sulair:SDR_DepositAgreement_GoogleBooks</dc:identifier>
  <dc:identifier>0a5690af-73ec-415e-aab7-6e2d3bd490a9</dc:identifier>
  <dc:identifier>sulair:SDR_DepositAgreement_GoogleBooks</dc:identifier>
  <dc:identifier>Agreement : GoogleBooks</dc:identifier>
  <dc:identifier>druid:zn292gq7284</dc:identifier>
</oai_dc:dc>
  EOXML
  
  descMetadata = <<-EOXML

<mods version="3.3">
  <titleInfo>
    <title>SDR Operating Agreement for Google Scanned Books</title>
  </titleInfo>
  <name type="corporate">
    <namePart>Stanford University Libraries, Stanford Digital Repository</namePart>
    <role>
      <text>creator</text>
    </role>
  </name>
  <typeOfResource>text</typeOfResource>
  <genre>internal document</genre>
  <originInfo>
    <publisher>Stanford University Libraries</publisher>
    <dateIssued>2010</dateIssued>
  </originInfo>
  <language authority="iso639-2b">eng</language>
</mods>

  EOXML
  
  contentMetadata  = <<-EOXML


<contentMetadata objectId="druid:zn292gq7284" type="agreement">
  <resource data="content" id="deposit_agreement" type="document">
    <file deliver="no" format="TEXT" id="OpLvlAgrmt_GoogleBooks.docx" mimetype="application/msword" preserve="yes" shelve="yes" size="22912">
      <location type="url">http://stacks.stanford.edu/file/OpLvlAgrmt_GoogleBooks.pdf</location>
      <checksum type="md5">733eb4024ac121a7bd36c90caf0cee1f</checksum>
      <checksum type="sha1">449bc271e9667f650f71c1fd33c11ccfd688e790</checksum>
    </file>
    <file deliver="no" format="PDF" id="OpLvlAgrmt_GoogleBooks.pdf" mimetype="application/pdf" preserve="yes" shelve="yes" size="94226">
      <location type="url">http://stacks.stanford.edu/file/OpLvlAgrmt_GoogleBooks.pdf</location>
      <checksum type="md5">1e4958a50c2e88c7e53e128d789b2bcf</checksum>
      <checksum type="sha1">77331f3b19c277a498446e0440031cb1dd26266d</checksum>
    </file>
  </resource>
</contentMetadata>
  EOXML
  
  agreementWF = <<-EOXML
  <workflow objectId='druid:zn292gq7284' id='agreementWF'>
  <process lifecycle='inprocess' elapsed='0.0' attempts='1' datetime='2010-05-27T13:39:48-0700' status='completed' name='register-object'/>
  <process elapsed='0.0' attempts='0' datetime='2010-05-27T13:39:48-0700' status='waiting' name='process-content'/>
  <process elapsed='0.0' attempts='0' datetime='2010-07-13T14:19:48-0700' status='waiting' name='sdr-ingest-transfer'/>
  <process elapsed='0.0' attempts='0' datetime='2010-07-14T13:39:48-0700' status='waiting' name='sdr-ingest-deposit'/>
  <process lifecycle='released' elapsed='0.0' attempts='0' datetime='2010-08-27T13:39:48-0700' status='waiting' name='shelve'/>
  <process lifecycle='accessioned' elapsed='0.0' attempts='0' datetime='2010-08-27T13:39:48-0700' status='waiting' name='cleanup'/>
  <process lifecycle='archived' elapsed='0.0' attempts='0' datetime='2010-08-27T13:39:48-0700' status='waiting' name='sdr-ingest-complete'/>
  </workflow>
  EOXML
  

  desc "Build the bootstrap agreement object in the specified Fedora repository"
  task :build_base_agreement_obj do
    unless ENV['ROBOT_ENVIRONMENT']
      puts "You haven't set a value for ROBOT_ENVIRONMENT so I don't know where to build the object."
      puts "Invoke this script like this: \n ROBOT_ENVIRONMENT=test rake objects:build_base_agreement_obj"
    else
      puts "Building base agreement obj in #{ENV['ROBOT_ENVIRONMENT']}"
      environment = ENV['ROBOT_ENVIRONMENT']
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environments/#{environment}")
      puts "Connecting to #{SEDORA_URI}..."
      Fedora::Repository.register(SEDORA_URI)
      ActiveFedora::SolrService.register(SOLR_URL)
      
      # Make sure we're starting with a blank object
      begin
        obj = ActiveFedora::Base.load_instance(PID)
        obj.delete
      rescue
        $stderr.print $!
      end
      
      # Create a new object
      obj = ActiveFedora::Base.new(:pid => PID)
      
      # Add the agreementWF
      agreementWFDS = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"agreementWF", :dsLabel=>"agreementWF", :blob=>agreementWF)
      obj.add_datastream(agreementWFDS)
      
      contentMetadataDS = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"contentMetadata", :dsLabel=>"contentMetadata", :blob=>contentMetadata)
      obj.add_datastream(contentMetadataDS)
      
      descMetadataDS = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"descMetadata", :dsLabel=>"descMetadata", :blob=>descMetadata)
      obj.add_datastream(descMetadataDS)
      
      identityMetadataDS = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"identityMetadata", :dsLabel=>"identityMetadata", :blob=>identityMetadata)
      obj.add_datastream(identityMetadataDS)
      
      dc_ds = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"DC", :dsLabel=>"Dublin Core Record for this object", :blob=>DC)
      obj.add_datastream(dc_ds)
      
      # Add the PDF as a managed datastream
      #file = File.new(File.expand_path(File.dirname(__FILE__) << '/' << 'OpLvlAgrmt_Agreements_v01.pdf'))
      #file_ds = ActiveFedora::Datastream.new(:dsID => "PDF", :dsLabel => 'PDF of Uber-Agreement', :controlGroup => 'M', :blob => file)
      #obj.add_datastream(file_ds)
      
      obj.save
      
      puts "The object should be available at #{SEDORA_URI}/get/#{PID}"
      
      # rels_ext_ds = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"RELS-EXT", :dsLabel=>"RELS-EXT", :blob=>rels_ext)
      # obj.add_datastream(rels_ext_ds)
      
    end
  end


end
