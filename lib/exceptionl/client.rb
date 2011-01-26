require 'exceptionl/exception_report'
require 'exceptionl/backend'
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
  #
  # * application_name: A tag representing the name of the app that
  #   this exception occurred in. This is used for advanced filtering
  #   on the server, if the server backend is used.
  #
  # * exception: The exception object that was thrown. This can also
  #   be a string, but you won't get information like the backtrace if
  #   you don't pass an actual exception subclass.
  #
  # * extra_data: A hash of additional data to log with the
  #   exception. Depending on which backend the server uses, this may
  #   or may not be indexable.
  def self.report(application_name, exception, extra_data = {})
    begin
      @backend.report(Exceptionl::ExceptionReport.new(:application => application_name, :exception => exception, :data => extra_data))
    rescue Exception => e # keep going if this fails
    end
  end

  # Calls +report+ on all exceptions raised in the provided block of
  # code. +options+ can be:
  #
  # [:reraise] if true, reraise exceptions caught in this
  #            block. Defaults to true.
  def self.report_exceptions(application_name, options = {})
    options = {:reraise => true}.merge(options)
    begin
      yield
    rescue => e
      report(application_name, e)
      if options[:reraise]
        raise e
      end
    end
  end
end

logfile = File.join(Dir.tmpdir, "exceptions.log")

# let's put this in a better place if we're using rails
logfile = Rails.root + 'log/exceptions.log' if defined?(Rails)

Exceptionl::Client.backend = Exceptionl::Backend::LogFile.new(logfile)
