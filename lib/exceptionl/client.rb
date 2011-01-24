require 'exceptionl/exception_report'
require 'exceptionl/backends'
require 'tempfile'

# The exceptionl client enables you to log exception data to a
# backend. The class method Exceptionl::Client.report is usually the
# method you want to use out of this class, although for those who
# like block syntax, this class also provides a +report_exceptions+
# method that reports all exceptions raised inside a block.
class Exceptionl::Client

  # Sets the backend the client will use to report exceptions to
  # +new_backend+, an Exceptionl::Backend instance. By default,
  # exceptions are logged using Exceptionl::Backend::LogFileBackend.
  def self.backend=(new_backend)
    @backend = new_backend
  end

  # Report an exception to the exception logging backend.
  def self.report(application_name, exception, extra_data = {})
    begin
      @backend.report(Exceptionl::ExceptionReport.new(:application => application_name, :exception => exception, :data => extra_data))
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
logfile = Rails.root + 'log/exceptions.log' if defined?(Rails)

Exceptionl::Client.backend = Exceptionl::Backend::LogFile.new(logfile)
