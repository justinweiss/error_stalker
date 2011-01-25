require 'exceptionl/store/base'

# The simplest exception store. This just stores each reported
# exception in a list held in memory. This, of course, means that the
# exception list will disappear when the server goes down, the server
# might take up tons of memory, and searching will probably be
# slow. In other words, this is a terrible choice for production. On
# the other hand, this store is especially useful for tests.
class Exceptionl::Store::InMemory < Exceptionl::Store::Base

  # The list of exceptions reported so far.
  attr_reader :exceptions

  # A hash of exceptions indexed by digest.
  attr_reader :exception_groups

  # Creates a new instance of this store.
  def initialize
    clear
  end

  # Store +exception_report+ in the exception list. This also indexes
  # the exception into the appropriate exception group.
  def store(exception_report)
    @exceptions << exception_report
    exception_report.id = exceptions.length - 1
    exception_groups[exception_report.digest] ||= []
    exception_groups[exception_report.digest] << exception_report
    exception_report.id
  end

  # returns the list of exceptions in the group matching +digest+, ordered by
  # timestamp. 
  def group(digest)
    exception_groups[digest]
  end
  
  # Empty this exception store. Useful for tests!
  def clear
    @exceptions = []
    @exception_groups = {}
  end

  # Find an exception report with the given id.
  def find(id)
    exceptions[id.to_i]
  end

  # Have we logged any exceptions?
  def empty?
    exceptions.empty?
  end

  # Return recent exceptions grouped by digest.
  def recent
    data = []
    exception_groups.map do |digest, group|
      data << Exceptionl::ExceptionGroup.new.tap do |g|
        g.count = group.length
        g.digest = digest
        g.timestamp = group.last.timestamp
        g.most_recent_report = group.last
      end
    end
     
    data.reverse
  end
end
