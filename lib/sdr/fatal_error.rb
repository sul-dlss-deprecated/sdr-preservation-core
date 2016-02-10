# A ServiceError is used to wrap timeouts, HTTP exceptions, etc
# And create a new exception that is usually treated as a fatal error
module Robots
  module SdrRepo

    class FatalError < StandardError
    end

  end
end