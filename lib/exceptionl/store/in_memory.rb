require 'exceptionl/store/base'

# The simplest exception store. This just stores each reported
# exception in a list held in memory.
class Exceptionl::Store::InMemory < Exceptionl::Store::Base
  attr_reader :exceptions
  attr_reader :exception_groups
  
  def initialize
    clear
  end

  # Store +exception_report+ in the exception list
  def store(exception_report)
    @exceptions << exception_report
    exception_report.id = exceptions.length - 1
    exception_groups[exception_report.digest] ||= []
    exception_groups[exception_report.digest] << exception_report
    exception_report.id
  end

  # returns the group this exception is a part of, ordered by
  # timestamp
  def group(digest)
    exception_groups[digest]
  end
  
  # Empty this exception store
  def clear
    @exceptions = []
    @exception_groups = {}
  end

  # Find an exception report with the given id
  def find(id)
    exceptions[id.to_i]
  end

  # Have we logged any exceptions?
  def empty?
    exceptions.empty?
  end

  # Return recent exceptions grouped by digest
  def recent
    data = []
    exception_groups.map do |digest, group|
      data << [group.count, group.last]
    end

    data.reverse
  end
end
