require File.join(File.dirname(__FILE__),'libdir')
require 'boot'

module Sdr

  # Creates +Sedora+ objects and workflow datastreams.
  class RegisterSdr < LyberCore::Robots::Robot

    def initialize()
      super('sdrIngestWF', 'register-sdr',
            :logfile => "#{Sdr::Config.logdir}/register-sdr.log",
            :loglevel => Logger::INFO,
            :options => ARGV[0])
      env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
    end

    # - Creates a *Sedora* object
    # - Adds the +sdrIngestWF+ datastream
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      register_item(work_item.druid)
    end

    def register_item(druid)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter register_item")
      if SedoraObject.exists?(druid)
        sedora_object = SedoraObject.find(druid)
      else
        sedora_object = SedoraObject.new(:pid=>druid)
        sedora_object.save
      end
      sedora_object.set_workflow_datastream_location
      sedora_object
    rescue Exception => e
      raise LyberCore::Exceptions::FatalError.new("Sedora Object cannot be found or created", e)
    end

  end

end

# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::RegisterSdr.new()
  dm_robot.start
end
