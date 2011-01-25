require 'json'
require 'net/http'

# Stores reported exceptions to a central Exceptionl server (a Rack
# server pointing to an Exceptionl::Server instance). The most
# complicated Exceptionl backend, it is also the most powerful. This
# is probably what you want to be using in production.
class Exceptionl::Backend::Server < Exceptionl::Backend::Base

  # The hostname of the Exceptionl server
  attr_accessor :host

  # The Exceptionl server's port
  attr_accessor :port

  # http or https
  attr_accessor :protocol

  # The path of the Exceptionl server, if applicable
  attr_accessor :path 
  
  # Creates a new Server backend instance that will report exceptions
  # to a centralized Exceptionl server.
  def initialize(params = {})
    @protocol = params[:protocol] || 'http://'
    @host = params[:host] || 'localhost'
    @port = params[:port] || '5678'
    @path = params[:path] || ''
  end

  # Reports +exception_report+ to a central Exceptionl server.
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
