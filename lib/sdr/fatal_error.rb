require File.join(File.dirname(__FILE__), 'chained_error')

# A ServiceError is used to wrap timeouts, HTTP exceptions, etc
# And create a new exception that is usually treated as a fatal error
module Sdr
    class FatalError < Sdr::ChainedError
  end
end