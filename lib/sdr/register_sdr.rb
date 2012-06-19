require File.join(File.dirname(__FILE__),'libdir')
require 'boot'

module Sdr

  # A robot for creating +Sedora+ objects and workflow datastreams unless they exist
  class RegisterSdr < LyberCore::Robots::Robot

    # set workflow name, step name, log location, log severity level
    def initialize()
      super('sdrIngestWF', 'register-sdr',
            :logfile => "#{Sdr::Config.logdir}/register-sdr.log",
            :loglevel => Logger::INFO,
            :options => ARGV[0])
      env = ENV['ROBOT_ENVIRONMENT']
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Environment is : #{env}")
      LyberCore::Log.debug("Process ID is : #{$PID}")
    end

    # @param work_item [LyberCore::Robots::WorkItem] The item to be processed
    # @return [void] process an object from the queue through this robot
    #   Overrides LyberCore::Robots::Robot.process_item method.
    #   See LyberCore::Robots::Robot#process_queue
    def process_item(work_item)
      LyberCore::Log.debug("( #{__FILE__} : #{__LINE__} ) Enter process_item")
      register_item(work_item.druid)
    end

    # @param druid [String] The object identifier
    # @return [SedoraObject]
    # - Creates a *Sedora* object unless it already exists
    # - Adds the +sdrIngestWF+ datastream to the Sedora object unless it already exists
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
