require 'boot'

workflow_url = Dor::Config.workflow.url
user_password = "#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}"
fedora_url = Sdr::Config.sedora.url.sub('//',"//#{user_password}@")
deposit_home = Sdr::Config.sdr_deposit_home
druid_id = Druid.split(/:/)[1]
druid_id =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
repository_path = File.join( Sdr::Config.storage_node, $1, $2, $3, $4, druid_id)

Robots = []

Robot = Struct.new(:name, :queries, :files)
Query = Struct.new(:url, :code, :expectation)
DataFile = Struct.new(:path)

Robots << robot = Robot.new("Sdr::RegisterSdr", [], [])
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

Robots << robot = Robot.new("Sdr::TransferObject", [], [])
robot.files << DataFile.new("#{deposit_home}/#{Druid}")

Robots << robot = Robot.new("Sdr::ValidateBag", [], [])
robot.files << DataFile.new("#{deposit_home}/#{Druid}/bag-info.txt")

Robots << robot = Robot.new("Sdr::PopulateMetadata", [], [])
robot.queries << Query.new(
    "#{fedora_url}/objects/#{Druid}/datastreams?format=xml", 200,
    /relationshipMetadata/
)

Robots << robot = Robot.new("Sdr::VerifyAgreement", [], [])

Robots << robot = Robot.new("Sdr::CompleteDeposit", [], [])
robot.queries << Query.new(
    "#{fedora_url}/objects/#{Druid}/datastreams/provenanceMetadata/content?format=xml", 200,
    /<agent name="SDR">/
)
robot.queries << Query.new(
    "https://localhost/sdr/objects/#{Druid}", 200,
    /<html>/
)
robot.files << DataFile.new("#{repository_path}")

