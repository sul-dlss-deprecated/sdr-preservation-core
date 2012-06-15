require File.join(File.dirname(__FILE__),'libdir')
require 'boot'

module Sdr

  class SdrDeposit
      # Returns the pair tree directory structure based on the given object identifier.
      # The object identifier must be in the SURI format, otherwise an exception is raised:
      # e.g. druid:aannnaannnn
      # where 'a' is an alphabetic character
      # where 'n' is a numeric character
      def self.druid_tree(druid)
        syntax_msg = "Identifier has invalid druid syntax: #{druid}"
        raise syntax_msg + "nil or empty" if druid.to_s.empty?
        namespace,identifier = druid.split(':')
        raise syntax_msg if (namespace.to_s.empty? || identifier.to_s.empty?)
        if(identifier =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/ )
          return File.join(namespace, $1, $2, $3, $4)
        else
          raise syntax_msg
        end
      end

      def self.druid_minus_prefix(druid)
        druid.split(/:/)[-1]
      end

      def self.bag_pathname(druid)
        return Pathname(Sdr::Config.sdr_deposit_home).join(druid_minus_prefix(druid))
      end

      def self.tarfile_pathaname(druid)
        "#{bag_pathname(druid)}.tar"
      end

  end

end
