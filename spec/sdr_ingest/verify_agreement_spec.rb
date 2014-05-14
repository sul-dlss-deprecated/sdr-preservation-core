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
    expect(@va).to be_an_instance_of(VerifyAgreement)
    expect(@va).to be_a_kind_of(LyberCore::Robot)
    expect(@va.class.workflow_name).to eq('sdrIngestWF')
    expect(@va.class.step_name).to eq('verify-agreement')
  end

  specify "VerifyAgreement#perform" do
    expect(@va).to receive(:verify_agreement).with(@druid)
    @va.perform(@druid)
  end

  describe "VerifyAgreement#verify_agreement" do

    specify "apo_id retrieved from relationship metadata and verified" do
      expect(@va).to receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      expect(@va).to receive(:find_relationship_metadata).with(@deposit_pathname).and_return(@relationship_md_pathname)
      expect(@va).to receive(:find_apo_id).with(@druid, @relationship_md_pathname).and_return(@apo_id)
      expect(@va).to receive(:verify_apo_id).with(@druid, @apo_id).and_return(true)
      expect(@va).to_not receive(:find_deposit_version)
      expect(@va.verify_agreement(@druid)).to eq(true)
    end

    specify "apo_id retrieved from relationship metadata but the APO object does not exist in storage" do
      expect(@va).to receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      expect(@va).to receive(:find_relationship_metadata).with(@deposit_pathname).and_return(@relationship_md_pathname)
      expect(@va).to receive(:find_apo_id).with(@druid, @relationship_md_pathname).and_return(@apo_id)
      expect(@va).to receive(:verify_apo_id).with(@druid, @apo_id).and_return(false)
      expect(@va).to_not receive(:find_deposit_version)
      expect{@va.verify_agreement(@druid)}.to raise_exception(/APO object aa111bb2222 was not found in repository/)
    end

    specify "apo_id could not be retrieved from an existing relationship metadata file" do
      expect(@va).to receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      expect(@va).to receive(:find_relationship_metadata).with(@deposit_pathname).and_return(@relationship_md_pathname)
      expect(@va).to receive(:find_apo_id).with(@druid, @relationship_md_pathname).and_return(nil)
      expect(@va).to_not receive(:verify_apo_id)
      expect(@va).to_not receive(:find_deposit_version)
      expect { @va.verify_agreement(@druid) }.to raise_exception(/APO ID not found in relationshipMetadata/)
    end

    specify "relationship metadata not found in deposit area, but that's OK because version > 1" do
      # relationship metadata not found in deposit area, but that's OK because version > 1
      expect(@va).to receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      expect(@va).to receive(:find_relationship_metadata).with(@deposit_pathname).and_return(nil)
      expect(@va).to_not receive(:find_apo_id)
      expect(@va).to_not receive(:verify_apo_id)
      expect(@va).to receive(:find_deposit_version).with(@druid, @deposit_pathname).and_return(2)
      expect(@va.verify_agreement(@druid)).to eq(true)
    end

    specify "relationship metadata not found in deposit area, raise error because version = 1" do
      # relationship metadata not found in deposit area, but that's OK because version > 1
      expect(@va).to receive(:find_deposit_pathname).with(@druid).and_return(@deposit_pathname)
      expect(@va).to receive(:find_relationship_metadata).with(@deposit_pathname).and_return(nil)
      expect(@va).to_not receive(:find_apo_id)
      expect(@va).to_not receive(:verify_apo_id)
      expect(@va).to receive(:find_deposit_version).with(@druid, @deposit_pathname).and_return(1)
      expect{@va.verify_agreement(@druid)}.to raise_exception(/relationshipMetadata.xml not found in deposited metadata files/)
    end

  end

  specify "VerifyAgreement#find_relationship_metadata" do
    deposit_pathname = @deposit_pathname
    reln_md_pathname = deposit_pathname.join('data','metadata','relationshipMetadata.xml')
    expect(@va.find_relationship_metadata(deposit_pathname)).to eq(reln_md_pathname)
    deposit_pathname = @deposit_pathname.parent.join('aa111bb2222')
    expect(@va.find_relationship_metadata(deposit_pathname)).to eq(nil)
  end

  specify "VerifyAgreement#find_deposit_version" do
    deposit_pathname = @deposit_pathname
    version = @va.find_deposit_version(@druid, deposit_pathname)
    expect(version).to eq(2)
    deposit_pathname = @deposit_pathname.parent.join('aa111bb2222')
    expect{@va.find_deposit_version(@druid, deposit_pathname)}.to raise_exception(/Unable to find deposit version/)
  end

  specify "VerifyAgreement#find_apo_id" do
    relationship_md_pathname = @va.find_relationship_metadata(@deposit_pathname)
    expect(@va.find_apo_id(@druid,relationship_md_pathname)).to eq("druid:wk434ht4838")
    relationship_md_pathname = @va.find_relationship_metadata(@deposit_pathname.parent)
    expect{@va.find_apo_id(@druid,relationship_md_pathname)}.to raise_exception(/Unable to find APO id in relationshipMetadata/)
  end

  specify "VerifyAgreement#verify_apo_id" do
    apo_druid = "druid:zn292gq7284"
    @va.valid_apo_ids << apo_druid
    expect(@va.verify_apo_id(@druid,apo_druid)).to eq(true)

    apo_druid = "druid:jq937jp0017"
    expect(@va.valid_apo_ids.include?(apo_druid)).to eq(false)
    expect(@va.verify_apo_id(@druid,apo_druid)).to eq(true)
    expect(@va.valid_apo_ids.include?(apo_druid)).to eq(true)

    apo_druid = "druid:bad"
    expect{@va.verify_apo_id(@druid,apo_druid)}.to raise_exception(/Unable to verify APO object/)

    @va.valid_apo_ids = nil
    expect{@va.verify_apo_id(@druid,apo_druid)}.to raise_exception(/undefined method/)
  end

end
