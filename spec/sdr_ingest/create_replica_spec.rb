require 'sdr_ingest/create_replica'
require 'spec_helper'
include Robots::SdrRepo::SdrIngest

describe CreateReplica do

  before(:all) do
    @object_id = "jc837rq9922"
    @druid = "druid:#{@object_id}"
  end

  before(:each) do
    @uc = CreateReplica.new
  end

  specify "CreateReplica#initialize" do
    expect(@uc).to be_an_instance_of(CreateReplica)
    expect(@uc).to be_a_kind_of(LyberCore::Robot)
    expect(@uc.class.workflow_name).to eq('sdrIngestWF')
    expect(@uc.class.step_name).to eq('create-replica')
  end

  # sdr_object = Replication::SdrObject.new(druid)
  # latest_version_id = sdr_object.current_version_id
  # sdr_object_version = Replication::SdrObjectVersion.new(sdr_object,latest_version_id)
  # replica = sdr_object_version.create_replica
  # replica.get_bag_data
  # replica.update_replica_data

  specify "CreateReplica#perform" do
    sdr_object_version = double(Replication::SdrObjectVersion)
    expect(Replication::SdrObjectVersion).to receive(:new).
         with(an_instance_of(Replication::SdrObject),3).and_return(sdr_object_version)
    replica = double(Replication::Replica)
    expect(sdr_object_version).to receive(:create_replica).and_return(replica)
    expect(replica).to receive(:get_bag_data)
    expect(replica).to receive(:catalog_replica_data)
    @uc.perform('druid:jq937jp0017')
  end

end
