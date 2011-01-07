require 'json'
require 'digest/md5'

# An ExceptionReport contains the exception data, which can then be
# transformed into whatever format is needed for further
# investigation.
class Exceptionl::ExceptionReport
  attr_reader :application, :machine, :timestamp, :type, :exception, :data, :backtrace
  attr_accessor :id

  # Build a new ExceptionReport. <tt>params[:application]</tt> is a
  # string identifying the application or component the exception was
  # sent from, <tt>params[:exception]</tt> is the exception object you
  # want to report (or a string error message), and
  # <tt>params[:data]</tt> is any extra arbitrary data you want to log
  # along with this report.
  def initialize(params = {})
    params = symbolize_keys(params)
    @id = params[:id]
    @application = params[:application]
    @machine = params[:machine] || machine_name
    @timestamp = params[:timestamp] || Time.now
    @type = params[:type] || params[:exception].class.name
    
    if params[:exception].is_a?(Exception)
      @exception = params[:exception].to_s
    else
      @exception = params[:exception]
    end
    
    @data = params[:data]
    
    if params[:backtrace]
      @backtrace = params[:backtrace]
    else
      @backtrace = params[:exception].backtrace if params[:exception].is_a?(Exception)
    end

    @digest = params[:digest] if params[:digest]
  end

  STACK_DIGEST_LENGTH = 4096

  # Generate a 'mostly-unique' hash code for this exception, that
  # should be the same for similar exceptions and different for
  # different exceptions. This is used to group similar exceptions
  # together.
  def digest
    @digest ||= Digest::MD5.hexdigest((backtrace ? backtrace.to_s[0,STACK_DIGEST_LENGTH] : exception.to_s) + type.to_s)
  end

  # Serialize this object to json, so we can send it over the wire
  def to_json
    {
      :application => application,
      :machine => machine,
      :timestamp => timestamp,
      :type => type,
      :exception => exception,
      :data => data,
      :backtrace => backtrace
    }.to_json
  end

  private

  # shamelessly stolen from rails
  def symbolize_keys(hash)
    hash.inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end
  
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
