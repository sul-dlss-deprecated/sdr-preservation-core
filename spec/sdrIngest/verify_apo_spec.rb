require 'rubygems'
require 'spec_helper'
require 'sdrIngest/verify_apo'
require 'fakeweb'

describe Sdr::VerifyApo do

  it "should extract an APO druid from a relationshipMetadata file" do
    relationship_md_pathname = @fixtures.join('dor_datastreams/relationshipMetadata.xml')
    apo_druid = Sdr::VerifyApo.get_apo_druid(relationship_md_pathname)
    apo_druid.should == 'druid:wk434ht4838'
  end

  it "should lookup a druid in fedora" do
    druid = "druid:ab123cd4567"
    sedora_uri = "http://sedora-test"
    FakeWeb.register_uri(:get, %r|#{sedora_uri}|,  {:body => "Post not found",  :status => ["404", "Not Found"]})
    FakeWeb.register_uri(:get, "#{sedora_uri}/objects/#{druid}", :body => "Hello World!")
    Sdr::VerifyApo.valid_apo_ids.size.should == 0
    Sdr::VerifyApo.verify_apo_in_fedora(druid, sedora_uri).should == true
    Sdr::VerifyApo.valid_apo_ids[0].should == druid
    Sdr::VerifyApo.verify_apo_in_fedora(druid, sedora_uri).should == true
    lambda{Sdr::VerifyApo.verify_apo_in_fedora("bad-druid", sedora_uri)}.should raise_exception(LyberCore::Exceptions::FatalError)
  end

end
