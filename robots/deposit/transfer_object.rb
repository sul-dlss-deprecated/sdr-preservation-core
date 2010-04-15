$:.unshift File.join(File.dirname(__FILE__), "..", "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "..", "robots")
$:.unshift File.join(File.dirname(__FILE__), "..", "..", "models")
require 'dor_service'
require 'rubygems'
require 'lyber_core'
require 'file_utilities'


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = PreIngest::TransferObject.new(
          'depositWorkflow', 'transfer-object')
  dm_robot.start
end

module PreIngest

# putting this code in a class method makes it easier to test
  class TransferObject < LyberCore::Robot

    def process_item(work_item)
      # Identifiers

      druid = work_item.druid
      FileUtilities.transfer_object(druid, source, dest)
    end
  end
end
