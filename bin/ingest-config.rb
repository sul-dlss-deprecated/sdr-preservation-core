require File.join(File.dirname(__FILE__), "robot-config.rb")

def get_robots(druid)

  druid_id = druid.split(/:/)[-1]
  druid_id =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
  repository_path = File.join( RepositoryHome, $1, $2, $3, $4, druid_id)
  
  robots = []
  
  robots << robot = Robot.new("Sdr::RegisterSdr", "sdr_ingest/register_sdr", [], [])
  robot.queries << Query.new(
      "#{FedoraUrl}/objects/#{druid}?format=xml", 200,
      /<objectProfile/
  )
  
  robots << robot = Robot.new("Sdr::TransferObject", "sdr_ingest/transfer_object", [], [])
  robot.files << DataFile.new("#{DepositHome}/#{druid_id}")
  
  robots << robot = Robot.new("Sdr::ValidateBag", "sdr_ingest/validate_bag", [], [])
  robot.files << DataFile.new("#{DepositHome}/#{druid_id}/bag-info.txt")
  
  robots << robot = Robot.new("Sdr::PopulateMetadata", "sdr_ingest/populate_metadata",[], [])
  robot.queries << Query.new(
      "#{FedoraUrl}/objects/#{druid}/datastreams?format=xml", 200,
      /relationshipMetadata/
  )
  
  robots << robot = Robot.new("Sdr::VerifyAgreement", "sdr_ingest/verify_agreement",[], [])
  
  robots << robot = Robot.new("Sdr::CompleteDeposit", "sdr_ingest/complete_deposit",[], [])
  robot.files << DataFile.new("#{repository_path}")

  robots

  end
