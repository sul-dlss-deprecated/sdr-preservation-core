class SdrDeposit
    # Returns the pair tree directory structure based on the given object identifier.
    # The object identifier must be in the SURI format, otherwise an exception is raised:
    #
    #     e.g. druid:aannnaannnn 
    #
    #       where 'a' is an alphabetic character
    #       where 'n' is a numeric character
    #
    def SdrDeposit.suri_pair_tree(suri)
      syntax_msg = "Identifier has invalid suri syntax: #{suri}"
      raise syntax_msg + "nil or empty" if suri.to_s.empty?
      namespace,identifier = suri.split(':')
      raise syntax_msg if (namespace.to_s.empty? || identifier.to_s.empty?)
      if(identifier =~ /^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/ )
        return File.join(namespace, $1, $2, $3, $4)
      else
        raise syntax_msg
      end
    end
    
    def SdrDeposit.local_bag_parent_dir(suri)
      return File.join(SDR_DEPOSIT_DIR, suri_pair_tree(suri))
    end
    
    def SdrDeposit.local_bag_path(suri)
      return File.join(SdrDeposit.local_bag_parent_dir(suri), suri)
    end

    def SdrDeposit.remote_bag_parent_dir(suri)
      return File.join(SDR_UNPACK_DIR, suri_pair_tree(suri))
    end

end