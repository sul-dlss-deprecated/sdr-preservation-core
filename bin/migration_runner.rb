#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), "robot_runner")

class MigrationRunner < RobotRunner

  # Class-level variable
  @robot_workflow = 'migration'

  def get_robots()
    robots = []
    robots << ["Sdr::MigrationStart", "sdr_migration/migration_start.rb"]
    robots << ["Sdr::MigrationRegister", "sdr_migration/migration_register.rb"]
    robots << ["Sdr::MigrationTransfer", "sdr_migration/migration_transfer.rb"]
    robots << ["Sdr::MigrationMetadata", "sdr_migration/migration_metadata.rb"]
    robots << ["Sdr::MigrationComplete", "sdr_migration/migration_complete.rb"]
    robots
  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  runner = MigrationRunner.new(ARGV)
  runner.process_queue
end
