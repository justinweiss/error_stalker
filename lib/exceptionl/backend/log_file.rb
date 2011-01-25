require 'yaml'

# A backend that logs all exception reports to a file. This is
# probably what you want to be running in development mode, and is
# also the default backend.
class Exceptionl::Backend::LogFile < Exceptionl::Backend::Base

  # The name of the file containing the exception reports
  attr_reader :filename

  # Creates a new LogFile backend that will log exceptions to +filename+
  def initialize(filename)
    @filename = filename
  end

  # Writes the information contained in +exception_report+ to the log
  # file specified when this backend was initialized.
  def report(exception_report)
    File.open(filename, 'a') do |file|
      file.puts "Machine: #{exception_report.machine}"
      file.puts "Application: #{exception_report.application}"
      file.puts "Timestamp: #{exception_report.timestamp}"
      file.puts "Type: #{exception_report.type}"
      file.puts "Exception: #{exception_report.exception}"
      file.puts "Data: #{YAML.dump(exception_report.data)}"
      if exception_report.backtrace
        file.puts "Stack trace:"
        file.puts exception_report.backtrace.join("\n")
      end
      file.puts
    end
  end
end
