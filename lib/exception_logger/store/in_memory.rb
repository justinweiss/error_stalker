require 'exception_logger/store/base'

# The simplest exception store. This just stores each reported
# exception in a list held in memory.
class ExceptionLogger::Store::InMemory < ExceptionLogger::Store::Base
  attr_reader :exceptions
  
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

  # Have we logged any exceptions?
  def empty?
    exceptions.empty?
  end

  # Return the last +limit+ unique exception reports that have been reported.
  def all(limit = 50)
    exceptions.reverse[0, 50]
  end
end
