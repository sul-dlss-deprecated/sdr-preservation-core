require_relative 'chained_error'

# A ItemError is used to wrap a causal exception
# And create a new exception that usually terminates processing of the current item
# the druid parameter makes it convenient to include the object id using a std message syntax
module Robots
  module SdrRepo

    class ItemError < ChainedError
      def initialize(druid, msg, cause=nil)
        if (druid)
          message = "#{druid} - #{msg}"
        else
          message= msg
        end
        super(message, cause)
      end
    end

  end
end