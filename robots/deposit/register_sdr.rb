$:.unshift File.join(File.dirname(__FILE__), "..", "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "..", "robots")
$:.unshift File.join(File.dirname(__FILE__), "..", "..", "models")
require 'dor_service'
require 'rubygems'
require 'lyber_core'


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = PreIngest::RegisterSdr.new(
          'depositWorkflow', 'register-object')
  dm_robot.start
end

module PreIngest

# putting this code in a class method makes it easier to test
  class RegisterSdr < LyberCore::Robot

    def process_item(work_item)
      # Identifiers

      druid = work_item.druid
    end
  end
end
