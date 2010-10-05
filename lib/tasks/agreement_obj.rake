require 'lyber_core'

namespace :objects do
  
  PID = "druid:tx617qp8040"
  
  rels_ext = <<-EOXML
  <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
  <rdf:Description rdf:about='info:fedora/druid:tx617qp8040'>
  <fedora-model:hasModel xmlns:fedora-model='info:fedora/fedora-system:def/model#' rdf:resource='info:fedora/dor:agreement'/>
  </rdf:Description>
  </rdf:RDF>
  EOXML
  
  identityMetadata = <<-EOXML
  <identityMetadata objectId='druid:tx617qp8040'>
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
  
  DC = <<-EOXML
  <oai_dc:dc xmlns:oai_dc='http://www.openarchives.org/OAI/2.0/oai_dc/' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd'>
  <dc:title xmlns:dc='http://purl.org/dc/elements/1.1/'>Agreement object for agreements</dc:title>
  <dc:identifier xmlns:dc='http://purl.org/dc/elements/1.1/'>sulair:SULAIR_agreement_agreement</dc:identifier>
  <dc:identifier xmlns:dc='http://purl.org/dc/elements/1.1/'>uuid:c2e47ead-9ab8-4da8-b447-a30f0e097ddd</dc:identifier>
  <dc:identifier xmlns:dc='http://purl.org/dc/elements/1.1/'>sulair:SULAIR_agreement_agreement</dc:identifier>
  <dc:identifier xmlns:dc='http://purl.org/dc/elements/1.1/'>druid:tx617qp8040</dc:identifier>
  </oai_dc:dc>
  EOXML
  
  descMetadata = <<-EOXML
  <mods version='3.3'>
  <titleInfo>
  <title>Agreement object for agreements</title>
  </titleInfo>
  <name type='corporate'>
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
  <language authority='iso639-2b'>eng</language>
  </mods>
  EOXML
  
  contentMetadata  = <<-EOXML
  <contentMetadata objectId='druid:tx617qp8040' type='agreement'>
  <resource data='content' id='deposit_agreement' type='document'>
  <file deliver='no' format='PDF' id='fileid.pdf' mimetype='application/pdf' preserve='yes' shelve='yes' size='58254'>
  <location type='url'>http://stacks.stanford.edu/file/OpLvlAgrmt_Agreements_v01.pdf</location>
  <checksum type='md5'>c7ccf47cdc9d2a691e81b1c2fe2ed29c</checksum>
  </file>
  </resource>
  </contentMetadata>
  EOXML
  
  agreementWF = <<-EOXML
  <workflow objectId='druid:tx617qp8040' id='agreementWF'>
  <process lifecycle='inprocess' elapsed='0.0' attempts='1' datetime='2010-05-27T13:39:48-0700' status='completed' name='register-object'/>
  <process elapsed='0.0' attempts='0' datetime='2010-05-27T13:39:48-0700' status='waiting' name='process-content'/>
  <process elapsed='0.0' attempts='0' datetime='2010-05-27T13:39:48-0700' status='waiting' name='sdr-ingest-transfer'/>
  <process elapsed='0.0' attempts='0' datetime='2010-05-27T13:39:48-0700' status='waiting' name='sdr-ingest-deposit'/>
  <process lifecycle='released' elapsed='0.0' attempts='0' datetime='2010-05-27T13:39:48-0700' status='waiting' name='shelve'/>
  <process lifecycle='accessioned' elapsed='0.0' attempts='0' datetime='2010-05-27T13:39:48-0700' status='waiting' name='cleanup'/>
  <process lifecycle='archived' elapsed='0.0' attempts='0' datetime='2010-05-27T13:39:48-0700' status='waiting' name='sdr-ingest-complete'/>
  </workflow>
  EOXML
  
  desc "Import the google books agreement object"
  task :google_agreement_obj do
    unless ENV['ROBOT_ENVIRONMENT']
      puts "You haven't set a value for ROBOT_ENVIRONMENT so I don't know where to build the object."
      puts "Invoke this script like this: \n ROBOT_ENVIRONMENT=test rake objects:build_agreement_obj"
    else
      puts "Building agreement obj in #{ENV['ROBOT_ENVIRONMENT']}"
      environment = ENV['ROBOT_ENVIRONMENT']
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environments/#{environment}")
      puts "Connecting to #{SEDORA_URI}..."
      Fedora::Repository.register(SEDORA_URI)
      ActiveFedora::SolrService.register(SOLR_URL)
      filename = File.expand_path(File.dirname(__FILE__) + '/google_books_agreement.xml')
      puts "Importing '#{filename}' to #{Fedora::Repository.instance.fedora_url}"
      file = File.new(filename, "r")
      result = foxml = Fedora::Repository.instance.ingest(file.read)
      if result
        puts "The agreement has been ingested as #{result}"
      else
        puts "Failed to ingest the google books agreement"
      end
    end
  end
  

  desc "Build the bootstrap agreement object in the specified Fedora repository"
  task :build_agreement_obj do
    unless ENV['ROBOT_ENVIRONMENT']
      puts "You haven't set a value for ROBOT_ENVIRONMENT so I don't know where to build the object."
      puts "Invoke this script like this: \n ROBOT_ENVIRONMENT=test rake objects:build_agreement_obj"
    else
      puts "Building agreement obj in #{ENV['ROBOT_ENVIRONMENT']}"
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
      file = File.new(File.expand_path(File.dirname(__FILE__) << '/' << 'OpLvlAgrmt_Agreements_v01.pdf'))
      file_ds = ActiveFedora::Datastream.new(:dsID => "PDF", :dsLabel => 'PDF of Uber-Agreement', :controlGroup => 'M', :blob => file)
      obj.add_datastream(file_ds)
      
      obj.save
      
      puts "The object should be available at #{SEDORA_URI}/get/#{PID}"
      
      # rels_ext_ds = ActiveFedora::Datastream.new(:pid=>PID, :dsid=>"RELS-EXT", :dsLabel=>"RELS-EXT", :blob=>rels_ext)
      # obj.add_datastream(rels_ext_ds)
      
    end
  end


end