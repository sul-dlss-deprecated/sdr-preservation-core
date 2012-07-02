require File.join(File.dirname(__FILE__),'libdir')
require 'boot'

module Sdr

  class DepositObject < DruidTools::Druid

    self.prefix = self.superclass.prefix

    def bag_pathname(verify=true)
      #todo change druid to id
      bag_pathname = Pathname(Sdr::Config.sdr_deposit_home).join(@druid)
      if verify and not bag_pathname.directory?
        raise LyberCore::Exceptions::ItemError.new(druid, "Can't find a bag at #{bag_pathname.to_s}")
      end
      bag_pathname
    end

    def tarfile_pathname()
      Pathname(Sdr::Config.sdr_deposit_home).join("#{@druid}.tar")
    end

  end

end
