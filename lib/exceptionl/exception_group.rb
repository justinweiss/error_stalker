# Container for information about a group of exceptions. This is used
# so that we don't get overwhelmed by duplicate exceptions. Some
# Exceptional::Stores may subclass and override this class, but the attributes
# called out here should always be valid.
class Exceptionl::ExceptionGroup
  # The number of times this exception has been reported
  attr_accessor :count

  # The unique identifier of this group. All similar exceptions should
  # generate the same digest.
  attr_accessor :digest

  # The most recent time this exception occurred
  attr_accessor :timestamp

  # The most recent ExceptionReport instance belonging to this group
  attr_accessor :most_recent_report
end
