require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'
require 'sdr_ingest/register_sdr'

module Sdr

  # A robot for ensuring that Sedora contains a proxy for each object and expected workflow datastreams
  # All methods inherit from the register-sdr robot's class, only the workflow name and step are changed
  class MigrationRegister < RegisterSdr

    @workflow_name = 'sdrMigrationWF'
    @workflow_step = 'migration-register'

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::MigrationRegister.new()
  dm_robot.start
end