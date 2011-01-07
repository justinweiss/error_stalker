require 'exceptionl/store/base'

# The simplest exception store. This just stores each reported
# exception in a list held in memory.
class Exceptionl::Store::InMemory < Exceptionl::Store::Base
  PER_PAGE = 25
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
  def group(digest, params = {})
    exception_groups[digest].paginate(:page => params[:page], :per_page => PER_PAGE)
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
  def recent(params = {})
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
