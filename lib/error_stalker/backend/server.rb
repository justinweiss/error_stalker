require 'json'
require 'net/http'

# Stores reported exceptions to a central ErrorStalker server (a Rack
# server pointing to an ErrorStalker::Server instance). The most
# complicated ErrorStalker backend, it is also the most powerful. This
# is probably what you want to be using in production.
class ErrorStalker::Backend::Server < ErrorStalker::Backend::Base

  # The hostname of the ErrorStalker server
  attr_accessor :host

  # The ErrorStalker server's port
  attr_accessor :port

  # http or https
  attr_accessor :protocol

  # The path of the ErrorStalker server, if applicable
  attr_accessor :path 
  
  # Creates a new Server backend instance that will report exceptions
  # to a centralized ErrorStalker server.
  def initialize(params = {})
    @protocol = params[:protocol] || 'http://'
    @host = params[:host] || 'localhost'
    @port = params[:port] || '5678'
    @path = params[:path] || ''
  end

  # Reports +exception_report+ to a central ErrorStalker server.
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
