#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'lyber_core'
require 'lyber_core/utils'
require 'logger'


module SdrIngest

# +TransferObject+ Transfers objects from DOR workspace to SDR's staging area.  
# - notifies DOR of success by: <b><i>need to be filled in</i></b>
# - notifies DOR of missing object by: <i><b>need to be filled in</b></i>

  class TransferObject < LyberCore::Robots::Robot
    
    # the destination object that gets created by running this script
    attr_reader :dest_path
    
    def initialize(string1,string2)
      super(string1,string2)

      @logg = Logger.new("transfer_object.log")
      @logg.level = Logger::DEBUG
      @logg.formatter = proc{|s,t,p,m|"%5s [%s] (%s) %s :: %s\n" % [s, 
                          t.strftime("%Y-%m-%d %H:%M:%S"), $$, p, m]}
    end
  	

    # Override the robot LyberCore::Robot.process_item method.
    # * Makes use of the Robot Framework FileUtilities.
    def process_item(work_item)
      @logg.debug("Enter process_item")
      # Identifiers
      druid = work_item.druid
      @dest_path = File.join(SDR_DEPOSIT_DIR,druid)
      @logg.debug("dest_path is : #{@dest_path}")
      if File.exists?(@dest_path)
        puts "Object already exists: #{@dest_path}"
      else
        # filename is druid.tar
        filename = druid + ".tar"
        @logg.debug("Tar file name being transferred is : #{filename}")
        return LyberCore::Utils::FileUtilities.transfer_object(filename, DOR_WORKSPACE_DIR, SDR_DEPOSIT_DIR)
        # TODO catch exceptions 
        @logg.debug("#{filename}  transferred to #{SDR_DEPOSIT_DIR}")
        
        # now untar the file directly in SDR_UNPACK_SERVER(sdr-thumper5)
        # e.g ssh sdr-thumper5 "cd ~/target/sdr2objects; tar xf 4177.tar"
        unpack-command = "ssh #{SDR_UNPACK_SERVER}  \"cd #{SDR_UNPACK_DIR}; tar xf filename\""
        @logg.debug("Unpack command is :  #{unpack-command}")
        status = system(unpack-command)
        @logg.debug("Return from untar is : #{status}")
        
      end
    end
  end
end


# This is the equivalent of a java main method
if __FILE__ == $0
  dm_robot = SdrIngest::TransferObject.new(
          'sdrIngestWF', 'transfer-object')
  dm_robot.start
end
