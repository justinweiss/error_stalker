# Container for information about a group of exceptions. This is used
# so that we don't get overwhelmed by duplicate exceptions. Some
# Exceptional::Stores may subclass and override this class, but the attributes
# called out here should always be valid.
class ErrorStalker::ExceptionGroup
  # The number of times this exception has been reported
  attr_accessor :count

  # The unique identifier of this group. All similar exceptions should
  # generate the same digest.
  attr_accessor :digest

  # The list of machines that have seen this exception
  attr_accessor :machines

  # The first time this exception occurred
  attr_accessor :first_timestamp

  # The most recent time this exception occurred
  attr_accessor :most_recent_timestamp

  # The most recent ExceptionReport instance belonging to this group
  attr_accessor :most_recent_report

  def type
    most_recent_report.type unless most_recent_report.nil?
  end

  def to_h
    {
      :count => count,
      :digest => digest,
      :machines => machines,
      :first_timestamp => first_timestamp.to_s,
      :most_recent_timestamp => most_recent_timestamp,
      :most_recent_report => most_recent_report.to_h
    }
  end

end
