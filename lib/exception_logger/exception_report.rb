
# An ExceptionReport contains the exception data, which can then be
# transformed into whatever format is needed for further
# investigation.
class ExceptionLogger::ExceptionReport
  attr_reader :application, :machine, :timestamp, :type, :exception, :data, :backtrace

  # Build a new ExceptionReport. +application+ is a string identifying
  # the application or component the exception was sent from,
  # +exception+ is the exception object you want to report (or a
  # string error message), and +data+ is any extra arbitrary data you
  # want to log along with this report.
  def initialize(application, exception, data = {})
    @application = application
    @machine = machine_name
    @timestamp = Time.now
    @type = exception.class.name
    @exception = exception
    @data = data
    @backtrace = exception.backtrace if exception.is_a?(Exception)
  end

  private
  def machine_name
    machine_name = 'unknown'
    if RUBY_PLATFORM =~ /win32/
      machine_name = ENV['COMPUTERNAME']
    elsif RUBY_PLATFORM =~ /linux/ || RUBY_PLATFORM =~ /darwin/
      machine_name = `/bin/hostname`.chomp
    end
    machine_name
  end
end
