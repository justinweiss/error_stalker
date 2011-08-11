# Provides an in-memory backend that stores all exception reports in
# an array. This is mostly useful for tests, and probably shouldn't be
# used in real code.
class ErrorStalker::Backend::InMemory < ErrorStalker::Backend::Base

  # A list of exceptions stored in this backend.
  attr_reader :exceptions

  # Create a new instance of this backend, with an empty exception
  # list.
  def initialize
    clear
  end

  # Stores exception_report in the exceptions list.
  def report(exception_report)
    @exceptions << exception_report
  end

  # Clears the exception list. Pretty useful in a test +setup+ method!
  def clear
    @exceptions = []
  end

end
