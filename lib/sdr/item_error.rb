# A ItemError is used to wrap a causal exception
# And create a new exception that usually terminates processing of the current item
module Robots
  module SdrRepo

    class ItemError < StandardError
    end

  end
end