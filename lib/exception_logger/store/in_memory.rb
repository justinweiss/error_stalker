require 'exception_logger/store/base'

# The simplest exception store. This just stores each reported
# exception in a list held in memory.
class ExceptionLogger::Store::InMemory < ExceptionLogger::Store::Base
  attr_accessor :exceptions
  
  def initialize
    clear
  end

  # Store +exception_report+ in the exception list
  def store(exception_report)
    @exceptions << exception_report
  end
  
  # Empty this exception store
  def clear
    @exceptions = []
  end

  # Return all the exception reports that have been reported.
  def all
    exceptions
  end
end
