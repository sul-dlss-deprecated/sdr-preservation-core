require 'sdr_ingest/verify_agreement'
require 'spec_helper'

describe Sdr::VerifyAgreement do

  before(:all) do
    @druid = "druid:jc837rq9922"
    @deposit_pathname = @fixtures.join('deposit','jc837rq9922')
    @relationship_md_pathname = @deposit_pathname.join(@druid)
    @apo_id = 'aa111bb2222'
  end

  before(:each) do
    @va = VerifyAgreement.new
  end

  specify "VerifyAgreement#initialize" do
    @va.should be_instance_of VerifyAgreement
    @va.should be_kind_of LyberCore::Robots::Robot
    @va.workflow.should be_kind_of(LyberCore::Robots::Workflow)
    @va.workflow_name.should == 'sdrIngestWF'
    @va.workflow_step.should == 'verify-agreement'
    LyberCore::Log.logfile.should eql("#{Sdr::Config.logdir}/verify-agreement.log")
    LyberCore::Log.level.should eql(Logger::INFO)
  end

  specify "VerifyAgreement#process_item" do
    work_item = double("WorkItem")
    work_item.stub(:druid).and_return(@druid)
    @va.should_receive(:verify_agreement).with(@druid)
    @va.process_item(work_item)
  end

  describe "VerifyAgreement#verify_agreement" do

    specify "apo_id retrieved from relationship metadata and verified" do
      @va.should_receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      @va.should_receive(:find_relationship_metadata).with(@deposit_pathname).and_return(@relationship_md_pathname)
      @va.should_receive(:find_apo_id).with(@druid, @relationship_md_pathname).and_return(@apo_id)
      @va.should_receive(:verify_apo_id).with(@druid, @apo_id).and_return(true)
      @va.should_not_receive(:find_deposit_version)
      @va.verify_agreement(@druid).should == true
    end

    specify "apo_id retrieved from relationship metadata but the APO object does not exist in storage" do
      @va.should_receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      @va.should_receive(:find_relationship_metadata).with(@deposit_pathname).and_return(@relationship_md_pathname)
      @va.should_receive(:find_apo_id).with(@druid, @relationship_md_pathname).and_return(@apo_id)
      @va.should_receive(:verify_apo_id).with(@druid, @apo_id).and_return(false)
      @va.should_not_receive(:find_deposit_version)
      lambda { @va.verify_agreement(@druid) }.should raise_exception(/APO object aa111bb2222 was not found in repository/)
    end

    specify "apo_id could not be retrieved from an existing relationship metadata file" do
      @va.should_receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      @va.should_receive(:find_relationship_metadata).with(@deposit_pathname).and_return(@relationship_md_pathname)
      @va.should_receive(:find_apo_id).with(@druid, @relationship_md_pathname).and_return(nil)
      @va.should_not_receive(:verify_apo_id)
      @va.should_not_receive(:find_deposit_version)
      lambda { @va.verify_agreement(@druid) }.should raise_exception(/APO ID not found in relationshipMetadata/)
    end

    specify "relationship metadata not found in deposit area, but that's OK because version > 1" do
      # relationship metadata not found in deposit area, but that's OK because version > 1
      @va.should_receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      @va.should_receive(:find_relationship_metadata).with(@deposit_pathname).and_return(nil)
      @va.should_not_receive(:find_apo_id)
      @va.should_not_receive(:verify_apo_id)
      @va.should_receive(:find_deposit_version).with(@druid, @deposit_pathname).and_return(2)
      @va.verify_agreement(@druid).should == true
    end

    specify "relationship metadata not found in deposit area, raise error because version = 1" do
      # relationship metadata not found in deposit area, but that's OK because version > 1
      @va.should_receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      @va.should_receive(:find_relationship_metadata).with(@deposit_pathname).and_return(nil)
      @va.should_not_receive(:find_apo_id)
      @va.should_not_receive(:verify_apo_id)
      @va.should_receive(:find_deposit_version).with(@druid, @deposit_pathname).and_return(1)
      lambda { @va.verify_agreement(@druid) }.should raise_exception(/relationshipMetadata.xml not found in deposited metadata files/)
    end

  end

  specify "VerifyAgreement#find_relationship_metadata" do
    deposit_pathname = @deposit_pathname
    reln_md_pathname = deposit_pathname.join('data','metadata','relationshipMetadata.xml')
    @va.find_relationship_metadata(deposit_pathname).should == reln_md_pathname
    deposit_pathname = @deposit_pathname.parent.join('aa111bb2222')
    @va.find_relationship_metadata(deposit_pathname).should == nil
  end

  specify "VerifyAgreement#find_deposit_version" do
    deposit_pathname = @deposit_pathname
    version = @va.find_deposit_version(@druid, deposit_pathname)
    version.should == 2
    deposit_pathname = @deposit_pathname.parent.join('aa111bb2222')
    lambda{@va.find_deposit_version(@druid, deposit_pathname)}.should raise_exception(/Unable to find deposit version/)
  end

  specify "VerifyAgreement#find_apo_id" do
    relationship_md_pathname = @va.find_relationship_metadata(@deposit_pathname)
    @va.find_apo_id(@druid,relationship_md_pathname).should == "druid:wk434ht4838"
    relationship_md_pathname = @va.find_relationship_metadata(@deposit_pathname.parent)
    lambda{@va.find_apo_id(@druid,relationship_md_pathname)}.should raise_exception(/Unable to find APO id in relationshipMetadata/)
  end

  specify "VerifyAgreement#verify_apo_id" do
    apo_druid = "druid:zn292gq7284"
    @va.valid_apo_ids << apo_druid
    @va.verify_apo_id(@druid,apo_druid).should == true

    apo_druid = "druid:jq937jp0017"
    @va.valid_apo_ids.include?(apo_druid).should == false
    @va.verify_apo_id(@druid,apo_druid).should == true
    @va.valid_apo_ids.include?(apo_druid).should == true

    apo_druid = "druid:bad"
    lambda{@va.verify_apo_id(@druid,apo_druid)}.should raise_exception(/Unable to verify APO object/)

    @va.valid_apo_ids = nil
    lambda{@va.verify_apo_id(@druid,apo_druid)}.should raise_exception(/undefined method/)
  end

end
