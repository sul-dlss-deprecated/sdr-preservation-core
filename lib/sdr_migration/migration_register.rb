require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'
require 'sdr_ingest/register_sdr'

module Sdr

  # A robot for ensuring that Sedora contains a proxy for each object and expected workflow datastreams
  # All methods inherit from the register-sdr robot's class, only the workflow name and step are changed
  class MigrationRegister < RegisterSdr

    @workflow_name = 'sdrMigrationWF'
    @workflow_step = 'migration-register'

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      register_item(work_item.druid)
    end


    def verification_queries(druid)
      user_password = "#{Sdr::Config.sedora.user}:#{Sdr::Config.sedora.password}"
      fedora_url = Sdr::Config.sedora.url.sub('//',"//#{user_password}@")
      queries = []
      queries << [
          "#{fedora_url}/objects/#{druid}/datastreams?format=xml",
          200, /<objectDatastreams/ ]
      queries << [
          "#{fedora_url}/objects/#{druid}?format=xml",
          200, /<objectProfile/ ]
      queries << [
          "#{fedora_url}/objects/#{druid}/datastreams/workflows?format=xml",
          200, /<dsLabel>Workflows<\/dsLabel>/ ]
      queries
    end

    def verification_files(druid)
      files = []
      files
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = Sdr::MigrationRegister.new()
  dm_robot.start
end