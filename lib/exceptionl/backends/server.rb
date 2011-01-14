require 'json'
require 'net/http'

# Provides a backend that logs all exception data to a file.
class Exceptionl::Backends::Server < Exceptionl::Backends::Base

  attr_accessor :host, :port, :protocol, :path 
  
  # Creates a new Server backend that will log exceptions to a
  # centralized server
  def initialize(params = {})
    @protocol = params[:protocol] || 'http://'
    @host = params[:host] || 'localhost'
    @port = params[:port] || '5678'
    @path = params[:path] || ''
  end

  # Reports +exception_report+ to a centralized
  # Exceptionl::Server.
  def report(exception_report)
    req = Net::HTTP::Post.new("#{path}/report.json")
    req["content-type"] = "application/json"
    req.body = exception_report.to_json
    http = Net::HTTP.new(host, port)
    http.read_timeout = 10
    res = http.start { |http| http.request(req) }
    res
  end
end
