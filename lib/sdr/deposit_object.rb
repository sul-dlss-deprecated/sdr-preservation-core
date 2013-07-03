require File.join(File.dirname(__FILE__),'../libdir')
require 'boot'

module Sdr

  class DepositObject < DruidTools::Druid

    self.prefix = self.superclass.prefix

    # @param verify [Boolean] If true, raise an error if the directory does not exist
    # @return [Pathname] The temp location of the bag containing the object version being deposited
    def bag_pathname(verify=true)
      bag_pathname = Pathname(Sdr::Config.sdr_deposit_home).join(@druid.sub('druid:',''))
      if verify and not bag_pathname.directory?
        raise LyberCore::Exceptions::ItemError.new(druid, "Can't find a bag at #{bag_pathname.to_s}")
      end
      bag_pathname
    end

    # @return [Pathname] The temp location of the tarfile containing the object version being deposited
    def tarfile_pathname()
      Pathname(Sdr::Config.sdr_deposit_home).join("#{@druid.sub('druid:','')}.tar")
    end

  end

end
