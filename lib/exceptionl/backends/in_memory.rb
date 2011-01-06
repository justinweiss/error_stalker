# Provides an in-memory backend that stores all exception reports in
# an array.
class Exceptionl::Backends::InMemory < Exceptionl::Backends::Base

  attr_reader :exceptions

  def initialize
    clear
  end

  # Stores exception_report in the exceptions list.
  def report(exception_report)
    @exceptions << exception_report
  end

  # Clears +exceptions+
  def clear
    @exceptions = []
  end

end
