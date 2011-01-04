require 'exception_logger/exception_report'
require 'exception_logger/backends/base'
require 'exception_logger/backends/log_file'
require 'tempfile'

# This class implements the client-side exception logging
# functionality. By default, it logs exceptions to a log file, though
# this can be overridden.
class ExceptionLogger::Client

  # Sets the backend the client will use to report exceptions to
  # +new_backend+
  def self.backend=(new_backend)
    @backend = new_backend
  end

  # Report an exception to the exception logging backend.
  def self.report(application_name, exception, extra_data = {})
    begin
      @backend.report(ExceptionLogger::ExceptionReport.new(:application => application_name, :exception => exception, :data => extra_data))
    rescue Exception => e # keep going if this fails
    end
  end

  # Report all exceptions that occur while running the passed-in block.
  def self.report_exceptions(application_name)
    begin
      yield
    rescue => e
      report(application_name, e)
    end
  end
end

logfile = File.join(Dir.tmpdir, "exceptions.log")

# let's put this in a better place if we're using rails
logfile = Rails.root + 'exceptions.log' if defined?(Rails)

ExceptionLogger::Client.backend = ExceptionLogger::Backends::LogFile.new(logfile)
