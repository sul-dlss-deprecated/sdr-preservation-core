require 'sdr_migration/migration_transfer'
require 'spec_helper'
include Robots::SdrRepo::SdrMigration

describe MigrationTransfer do

  before(:all) do
    @object_id = "jq937jp0017"
    @druid = "druid:#{@object_id}"
    @deposit_bag_pathname = @fixtures.join("deposit/#{@object_id}")
  end

  before(:each) do
    @mt = MigrationTransfer.new
  end

  specify "MigrationTransfer#initialize" do
    expect(@mt).to be_an_instance_of(MigrationTransfer)
    expect(@mt.class.superclass).to eq(Robots::SdrRepo::SdrIngest::TransferObject)
    expect(@mt).to be_a_kind_of(LyberCore::Robot)
    expect(@mt.class.workflow_name).to eq('sdrMigrationWF')
    expect(@mt.class.step_name).to eq('migration-transfer')
  end

  specify "MigrationTransfer#perform" do
    expect(@mt).to receive(:transfer_object).with(@druid)
    @mt.perform(@druid)
  end
  
  specify "MigrationTransfer#generate_inventory_manifests" do
    version_inventory = Moab::FileInventory.new(:type=>"version",:digital_object_id=>@druid, :version_id=>1)
    version_additions = Moab::FileInventory.new(:type=>"additons",:digital_object_id=>@druid, :version_id=>1)
    expect(@mt).to receive(:get_version_inventory).with(@druid, @deposit_bag_pathname).and_return(version_inventory)
    expect(version_inventory).to receive(:write_xml_file).with(@deposit_bag_pathname)
    expect(@mt).to receive(:get_version_additions).with(@druid, version_inventory).and_return(version_additions)
    expect(version_additions).to receive(:write_xml_file).with(@deposit_bag_pathname)
    @mt.generate_inventory_manifests(@druid, @deposit_bag_pathname)
  end

  specify "MigrationTransfer#get_version_inventory" do
    expect(@mt).to receive(:write_content_metadata).with(an_instance_of(String),an_instance_of(Pathname))
    version_inventory = @mt.get_version_inventory(@druid, @deposit_bag_pathname)
    expect(version_inventory).to be_an_instance_of(Moab::FileInventory)
    expect(version_inventory.group('content').files.size).to eq(6)
    expect(version_inventory.group('metadata').files.size).to eq(5)
    actual = version_inventory.group('content').files[0].signature.to_xml
    expected = <<-EOF
          <fileSignature size="41981" md5="915c0305bf50c55143f1506295dc122c"
               sha1="60448956fbe069979fce6a6e55dba4ce1f915178"
               sha256="4943c6ffdea7e33b74fd7918de900de60e9073148302b0ad1bf5df0e6cec032a"/>
          EOF
    expect(EquivalentXml.equivalent?(actual,expected)).to eq(true)
  end

  specify "MigrationTransfer#get_data_group" do
    data_group = @mt.get_data_group(@deposit_bag_pathname, 'content')
    expect(data_group.group_id).to eq('content')
    expect(data_group.files.size).to eq(6)
  end

  specify "MigrationTransfer#upgrade_content_metadata" do
    content_group = @mt.get_data_group(@deposit_bag_pathname, 'content')
    expect(@mt).to receive(:write_content_metadata).with(an_instance_of(String),an_instance_of(Pathname))
    content_metadata = @mt.upgrade_content_metadata(@deposit_bag_pathname, content_group)
    expected = <<-EOF
      <contentMetadata type="sample" objectId="druid:jq937jp0017">
        <resource type="version" sequence="1" id="version-1">
          <file datetime="2012-03-26T08:15:11-06:00" size="40873" id="title.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">1a726cd7963bd6d3ceb10a8c353ec166</checksum>
            <checksum type="SHA-1">583220e0572640abcd3ddd97393d224e8053a6ad</checksum>
            <checksum type="SHA-256">8b0cee693a3cf93cf85220dd67c5dc017a7edcdb59cde8fa7b7f697be162b0c5</checksum>
          </file>
          <file datetime="2012-03-26T08:20:35-06:00" size="41981" id="intro-1.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">915c0305bf50c55143f1506295dc122c</checksum>
            <checksum type="SHA-1">60448956fbe069979fce6a6e55dba4ce1f915178</checksum>
            <checksum type="SHA-256">4943c6ffdea7e33b74fd7918de900de60e9073148302b0ad1bf5df0e6cec032a</checksum>
          </file>
          <file datetime="2012-03-26T08:19:30-06:00" size="39850" id="intro-2.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">77f1a4efdcea6a476505df9b9fba82a7</checksum>
            <checksum type="SHA-1">a49ae3f3771d99ceea13ec825c9c2b73fc1a9915</checksum>
            <checksum type="SHA-256">3a28718a8867e4329cd0363a84aee1c614d0f11229a82e87c6c5072a6e1b15e7</checksum>
          </file>
          <file datetime="2012-03-26T09:59:14-06:00" size="25153" id="page-1.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">3dee12fb4f1c28351c7482b76ff76ae4</checksum>
            <checksum type="SHA-1">906c1314f3ab344563acbbbe2c7930f08429e35b</checksum>
            <checksum type="SHA-256">41aaf8598c9d8e3ee5d55efb9be11c542099d9f994b5935995d0abea231b8bad</checksum>
          </file>
          <file datetime="2012-03-26T09:23:36-06:00" size="39450" id="page-2.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">82fc107c88446a3119a51a8663d1e955</checksum>
            <checksum type="SHA-1">d0857baa307a2e9efff42467b5abd4e1cf40fcd5</checksum>
            <checksum type="SHA-256">235de16df4804858aefb7690baf593fb572d64bb6875ec522a4eea1f4189b5f0</checksum>
          </file>
          <file datetime="2012-03-26T09:24:39-06:00" size="19125" id="page-3.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">a5099878de7e2e064432d6df44ca8827</checksum>
            <checksum type="SHA-1">c0ccac433cf02a6cee89c14f9ba6072a184447a2</checksum>
            <checksum type="SHA-256">7bd120459eff0ecd21df94271e5c14771bfca5137d1dd74117b6a37123dfe271</checksum>
          </file>
        </resource>
      </contentMetadata>
    EOF
    expect(EquivalentXml.equivalent?(content_metadata,expected)).to eq(true)
  end

  specify "MigrationTransfer#get_version_additions" do
    expect(@mt).to receive(:write_content_metadata).with(an_instance_of(String),an_instance_of(Pathname))
    version_inventory = @mt.get_version_inventory(@druid, @deposit_bag_pathname)
    version_additions = @mt.get_version_additions(@druid, version_inventory)
    expect(version_additions.group('content').files.size).to eq(6)
    expect(version_additions.group('metadata').files.size).to eq(5)
    actual = version_additions.group('content').files[0].signature.to_xml
    expected = <<-EOF
      <fileSignature size="41981" md5="915c0305bf50c55143f1506295dc122c"
           sha1="60448956fbe069979fce6a6e55dba4ce1f915178"
           sha256="4943c6ffdea7e33b74fd7918de900de60e9073148302b0ad1bf5df0e6cec032a"/>
      EOF
    expect(EquivalentXml.equivalent?(actual,expected)).to eq(true)
  end

end
