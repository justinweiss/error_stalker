require 'exceptionl/store/base'
require 'set'

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

  # All the machines that have seen exceptions
  attr_reader :machines

  # All the applications that have seen exceptions
  attr_reader :applications

  # Creates a new instance of this store.
  def initialize
    clear
  end

  # Store +exception_report+ in the exception list. This also indexes
  # the exception into the appropriate exception group.
  def store(exception_report)
    @exceptions << exception_report
    self.machines << exception_report.machine
    self.applications << exception_report.application
    exception_report.id = exceptions.length - 1
    exception_groups[exception_report.digest] ||= []
    exception_groups[exception_report.digest] << exception_report
    exception_report.id
  end

  # Returns a list of exceptions whose digest is +digest+.
  def reports_in_group(digest)
    exception_groups[digest]
  end
  
  # returns the exception group matching +digest+
  def group(digest)
    build_group_for_exceptions(reports_in_group(digest))
  end
  
  # Empty this exception store. Useful for tests!
  def clear
    @exceptions = []
    @exception_groups = {}
    @machines = Set.new
    @applications = Set.new
  end
  
  # Searches for exception reports maching +params+.
  def search(params = {})
    results = exceptions
    results = results.select {|e| e.machine == params[:machine]} if params[:machine] && !params[:machine].empty?
    results = results.select {|e| e.application == params[:application]} if params[:application] && !params[:application].empty?
    results = results.select {|e| e.exception.to_s =~ /#{params[:exception]}/} if params[:exception] && !params[:exception].empty?
    results = results.select {|e| e.type.to_s =~ /#{params[:type]}/} if params[:type] && !params[:type].empty?
    results.reverse
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
      data << build_group_for_exceptions(group)
    end
     
    data.reverse
  end

  protected

  def build_group_for_exceptions(group)
    Exceptionl::ExceptionGroup.new.tap do |g|
      g.count = group.length
      g.digest = group.first.digest
      g.machines = group.map(&:machine).uniq
      g.first_timestamp = group.first.timestamp
      g.most_recent_timestamp = group.last.timestamp
      g.most_recent_report = group.last
    end
  end
end
