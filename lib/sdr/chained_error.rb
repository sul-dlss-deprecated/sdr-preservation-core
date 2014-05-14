# Provices a wrapping a caught exception inside a new exception.
# The original exception is optionally passed in as the cause parameter of the constructor
# see: http://ruby.runpaint.org/exceptions
# see: http://en.wikipedia.org/wiki/Exception_chaining
# see: http://www.ruby-forum.com/topic/148193
# see: http://jqr.github.com/2009/02/11/passing-data-with-ruby-exceptions.html
module Sdr
  class ChainedError < StandardError
    def initialize(message, cause=nil)
      if (cause && cause.is_a?(Exception))
        # exaample: "My message; caused by #<Interrupt: interrupt message>"
        super("#{message}; caused by #{cause.inspect}")
        self.set_backtrace(cause.backtrace)
      else
        super(message)
      end
    end
  end
end