require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  # A robot for creating +Sedora+ objects and workflow datastreams unless they exist
  class RegisterSdr < LyberCore::Robots::Robot

    # define class instance variables and getter method so that we can inherit from this class
    @workflow_name = 'sdrIngestWF'
    @workflow_step = 'register-sdr'
    class << self
      attr_accessor :workflow_name
      attr_accessor :workflow_step
    end

    # set workflow name, step name, log location, log severity level
    def initialize(opts = {})
      super(self.class.workflow_name, self.class.workflow_step, opts)
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
  dm_robot = Sdr::RegisterSdr.new()
  dm_robot.start
end
