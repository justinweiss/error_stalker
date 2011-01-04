require 'sinatra/base'

$: << File.expand_path('..', File.dirname(__FILE__))
require 'exception_logger'
require 'exception_logger/store/in_memory'

module ExceptionLogger
  
  class Server < Sinatra::Base
    attr_accessor :store

    set :root, File.dirname(__FILE__)
    set :public, Proc.new { File.join(root, "server/public") }
    set :views, Proc.new { File.join(root, "server/views") }

    def initialize
      super
      @store = ExceptionLogger::Store::InMemory.new
    end
    
    get '/' do
      store.all.map {|r| r.exception }
    end

    post '/report.json' do
      report = ExceptionLogger::ExceptionReport.new(JSON.parse(request.body.read))
      store.store(report)
      200
    end
    
  end
end
