require 'boot'
require 'socket'

storage_url = Sdr::Config.sdr_storage_url
workflow_url = Dor::Config.workflow.url
user_password = "#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}"
fedora_url = Sdr::Config.sedora.url.sub('//',"//#{user_password}@")
deposit_home = Sdr::Config.sdr_deposit_home
druid_id = Druid.split(/:/)[1]
druid_id =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
repository_path = File.join( Sdr::Config.storage_node, $1, $2, $3, $4, druid_id)

Robots = []

Robot = Struct.new(:name, :path, :queries, :files)
Query = Struct.new(:url, :code, :expectation)
DataFile = Struct.new(:path)

Robots << robot = Robot.new("Sdr::MigrationStart", "sdr_migration/migration_start.rb", [], [])
robot.queries << Query.new(
    "#{workflow_url}/sdr/objects/#{Druid}/workflows/sdrMigrationWF", 200,
    /completed/
)

Robots << robot = Robot.new("Sdr::MigrationRegister", "sdr_migration/migration_register.rb", [], [])
robot.queries << Query.new(
    "#{fedora_url}/objects/#{Druid}?format=xml", 200,
    /<objectProfile/
)
robot.queries << Query.new(
    "#{fedora_url}/objects/#{Druid}/datastreams?format=xml", 200,
    /<objectDatastreams/
)
robot.queries << Query.new(
    "#{fedora_url}/objects/#{Druid}/datastreams/workflows?format=xml", 200,
    /<dsLabel>Workflows<\/dsLabel>/
)

Robots << robot = Robot.new("Sdr::MigrationTransfer", "sdr_migration/migration_transfer.rb", [], [])
robot.files << DataFile.new("#{deposit_home}/#{Druid}")
robot.files << DataFile.new("#{deposit_home}/#{Druid}/bag-info.txt")

Robots << robot = Robot.new("Sdr::MigrationMetadata", "sdr_migration/migration_metadata.rb",[], [])
robot.queries << Query.new(
    "#{fedora_url}/objects/#{Druid}/datastreams?format=xml", 200,
    /versionMetadata/
)

Robots << robot = Robot.new("Sdr::MigrationComplete", "sdr_migration/migration_complete.rb",[], [])

robot.queries << Query.new(
    "#{storage_url}/objects/#{Druid}", 200,
    /<html>/
)
robot.queries << Query.new(
    "#{workflow_url}/sdr/objects/#{Druid}/workflows/sdrMigrationWF", 200,
    /completed/
)
robot.files << DataFile.new("#{repository_path}")

