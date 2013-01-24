require File.join(File.dirname(__FILE__), "robot-config.rb")

def get_robots(druid)
  
  druid_id = druid.split(/:/)[-1]
  druid_id =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
  repository_path = File.join( RepositoryHome, $1, $2, $3, $4, druid_id)
  
  robots = []
 
  robots << robot = Robot.new("Sdr::MigrationStart", "sdr_migration/migration_start.rb", [], [])
  robot.queries << Query.new(
      "#{WorkflowUrl}/sdr/objects/#{druid}/workflows/sdrMigrationWF", 200,
      /completed/
  )
  
  robots << robot = Robot.new("Sdr::MigrationRegister", "sdr_migration/migration_register.rb", [], [])
  robot.queries << Query.new(
      "#{FedoraUrl}/objects/#{druid}/datastreams?format=xml", 200,
      /<objectDatastreams/
  )

  robots << robot = Robot.new("Sdr::MigrationTransfer", "sdr_migration/migration_transfer.rb", [], [])
  robot.files << DataFile.new("#{DepositHome}/#{druid_id}")

  robots << robot = Robot.new("Sdr::MigrationMetadata", "sdr_migration/migration_metadata.rb",[], [])
  robot.queries << Query.new(
      "#{FedoraUrl}/objects/#{druid}/datastreams?format=xml", 200,
      /versionMetadata/
  )
  
  robots << robot = Robot.new("Sdr::MigrationComplete", "sdr_migration/migration_complete.rb",[], [])
  robot.files << DataFile.new("#{repository_path}")
  
  robots
    
end
