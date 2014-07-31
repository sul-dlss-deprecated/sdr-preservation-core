require 'sdr_ingest/update_catalog'
require 'spec_helper'
include Robots::SdrRepo::SdrIngest

describe UpdateCatalog do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @uc = UpdateCatalog.new
  end

  specify "UpdateCatalog#initialize" do
    expect(@uc).to be_an_instance_of(UpdateCatalog)
    expect(@uc).to be_a_kind_of(LyberCore::Robot)
    expect(@uc.class.workflow_name).to eq('sdrIngestWF')
    expect(@uc.class.step_name).to eq('update-catalog')
  end

  # sdr_object = Replication::SdrObject.new(druid)
  # latest_version_id = sdr_object.current_version_id
  # sdr_object_version = Replication::SdrObjectVersion.new(sdr_object,latest_version_id)
  # sdr_object_version.update_object_data
  # sdr_object_version.update_version_data

  specify "UpdateCatalog#perform" do
    sdr_object_version = double(Replication::SdrObjectVersion)
    expect(Replication::SdrObjectVersion).to receive(:new).
         with(an_instance_of(Replication::SdrObject),3).and_return(sdr_object_version)
    expect(sdr_object_version).to receive(:catalog_object_data)
    expect(sdr_object_version).to receive(:catalog_version_data)
    @uc.perform('druid:jq937jp0017')
  end

end
