require 'sdr/verify_agreement'
require 'spec_helper'

describe Sdr::VerifyAgreement do

  before(:all) do
    @druid = "druid:jc837rq9922"

  end

  before(:each) do
    @va = VerifyAgreement.new
  end

  specify "VerifyAgreement#initialize" do
    @va.should be_instance_of VerifyAgreement
    @va.should be_kind_of LyberCore::Robots::Robot
    @va.workflow_name.should == 'sdrIngestWF'
    @va.workflow_step.should == 'verify-agreement'
  end

  specify "VerifyAgreement#process_item" do
    work_item = mock("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @va.should_receive(:verify_agreement).with(@druid)
    @va.process_item(work_item)
  end

  specify "VerifyAgreement#verify_agreement true true na na" do
    @va.should_receive(:find_apo_id).with(@druid).and_return('valid_apo_id')
    @va.should_receive(:verify_identifier).with('valid_apo_id').and_return(true)
    @va.should_not_receive(:find_agreement_id)
    @va.verify_agreement(@druid).should == true
  end

  specify "VerifyAgreement#verify_agreement true false true true" do
    @va.should_receive(:find_apo_id).with(@druid).and_return('invalid_apo_id')
    @va.should_receive(:verify_identifier).with('invalid_apo_id').and_return(false)
    @va.should_receive(:find_agreement_id).with(@druid).and_return('valid_agreement_id')
    @va.should_receive(:verify_identifier).with('valid_agreement_id').and_return(true)
    @va.verify_agreement(@druid).should == true
  end

  specify "VerifyAgreement#verify_agreement false na true true" do
    @va.should_receive(:find_apo_id).with(@druid).and_return(nil)
    @va.should_receive(:find_agreement_id).with(@druid).and_return('valid_agreement_id')
    @va.should_receive(:verify_identifier).with('valid_agreement_id').and_return(true)
    @va.verify_agreement(@druid).should == true
  end

  specify "VerifyAgreement#verify_agreement false na true false" do
    @va.should_receive(:find_apo_id).with(@druid).and_return(nil)
    @va.should_receive(:find_agreement_id).with(@druid).and_return('invalid_agreement_id')
    @va.should_receive(:verify_identifier).with('invalid_agreement_id').and_return(false)
    lambda{@va.verify_agreement(@druid)}.should raise_exception(LyberCore::Exceptions::ItemError)
  end

  specify "VerifyAgreement#verify_agreement false na false na" do
    @va.should_receive(:find_apo_id).with(@druid).and_return(nil)
    @va.should_receive(:find_agreement_id).with(@druid).and_return(nil)
    lambda{@va.verify_agreement(@druid)}.should raise_exception(LyberCore::Exceptions::ItemError)
  end

  specify "VerifyAgreement#find_apo_id" do
    @va.stub(:get_metadata).with(@druid,'relationshipMetadata').and_return(<<-EOF
      <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rel="info:fedora/fedora-system:def/relations-external#" xmlns:hydra="http://projecthydra.org/ns/relations#">
        <rdf:Description rdf:about="info:fedora/druid:ab123cd4567">
          <hydra:isGovernedBy rdf:resource="info:fedora/druid:wk434ht4838"></hydra:isGovernedBy>
        </rdf:Description>
      </rdf:RDF>
    EOF
    )
    @va.find_apo_id(@druid).should == "druid:wk434ht4838"

    @va.stub(:get_metadata).with(@druid,'relationshipMetadata').and_return(nil)
    @va.find_apo_id(@druid).should == nil

    @va.stub(:get_metadata).with(@druid,'relationshipMetadata').and_return(<<-EOF
      <rdf:RDF xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rel="info:fedora/fedora-system:def/relations-external#" xmlns:hydra="http://projecthydra.org/ns/relations#">
      </rdf:RDF>
    EOF
    )
    @va.find_apo_id(@druid).should == nil

  end

  specify "VerifyAgreement#find_agreement_id" do
    @va.should_receive(:get_metadata).with(@druid,'identityMetadata').and_return(<<-EOF
      <identityMetadata>
        <objectId>druid:bp119bq5041</objectId>
        <objectType>item</objectType>
        <objectLabel>google download barcode 36105033436945</objectLabel>
        <objectCreator>DOR</objectCreator>
        <citationTitle>Why go to college?: An address</citationTitle>
        <citationCreator>Palmer, Alice Freeman , 1855-1902</citationCreator>
        <sourceId source="google">STANFORD_36105033436945</sourceId>
        <otherId name="shelfseq">376.6 .P173</otherId>
        <otherId name="catkey">2223292</otherId>
        <otherId name="barcode">36105033436945</otherId>
        <otherId name="callseq">2</otherId>
        <otherId name="uuid">66ec8966-a04b-4155-aea4-f7443923ae72</otherId>
        <agreementId>druid:zn292gq7284</agreementId>
        <tag>Google Book : Phase 1</tag>
        <tag>Google Book : Scan source STANFORD</tag>
        <tag>Google Book : US pre-1923</tag>
      </identityMetadata>
    EOF
    )
    @va.find_agreement_id(@druid).should == "druid:zn292gq7284"

    @va.should_receive(:get_metadata).with(@druid,'identityMetadata').and_return(nil)
    @va.find_agreement_id(@druid).should == nil

    @va.should_receive(:get_metadata).with(@druid,'identityMetadata').and_return(<<-EOF
      <identityMetadata>
      </identityMetadata>
    EOF
    )
    @va.find_agreement_id(@druid).should == nil

  end

  specify "VerifyAgreement#get_metadata" do
    bag_pathname = mock("bag_pathname")
    relationship_metadata_pathaname = mock("relationship_metadata_pathaname")
    SdrDeposit.stub(:bag_pathname).with(@druid).and_return(bag_pathname)
    bag_pathname.stub(:join).with('data/metadata/relationshipMetadata.xml').
        and_return(relationship_metadata_pathaname)
    relationship_metadata_pathaname.stub(:read).and_return("<relationshipMetadata>...")
    relationship_metadata_pathaname.stub(:exist?).and_return(true)
    @va.get_metadata(@druid,'relationshipMetadata').should == "<relationshipMetadata>..."

    relationship_metadata_pathaname.stub(:exist?).and_return(false)
    @va.get_metadata(@druid,'relationshipMetadata').should == nil
  end

  specify "VerifyAgreement#verify_identifier" do
    @va.valid_identifiers << "druid:zn292gq7284"
    @va.verify_identifier("druid:zn292gq7284").should == true

    SedoraObject.stub(:exists?).with("druid:wk434ht4838").and_return(true)
    @va.valid_identifiers.include?("druid:wk434ht4838").should == false
    @va.verify_identifier("druid:wk434ht4838").should == true
    @va.valid_identifiers.include?("druid:wk434ht4838").should == true

    SedoraObject.stub(:exists?).with("druid:bad").and_return(false)
    @va.verify_identifier("druid:bad").should == false

    #def verify_identifier(identifier)
    #  LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter verify_identifier")
    #  if @valid_identifiers.include?(identifier)
    #    true
    #  elsif SedoraObject.exists?(agreement_id)
    #    @valid_identifiers << agreement_id
    #    true
    #  else
    #    false
    #  end
    #rescue Exception => e
    #  raise LyberCore::Exceptions::FatalError.new("unable to verify identifier", e)
    #end

  end

end
