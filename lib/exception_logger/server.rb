require 'sinatra/base'

$: << File.expand_path('..', File.dirname(__FILE__))
require 'exception_logger'
require 'exception_logger/store/in_memory'
require 'exception_logger/store/mongoid'
require 'erb'

module ExceptionLogger
  
  class Server < Sinatra::Base
    attr_accessor :store

    set :root, File.dirname(__FILE__)
    set :public, Proc.new { File.join(root, "server/public") }
    set :views, Proc.new { File.join(root, "server/views") }

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html
      
      def url(*path_parts)
        u = '/' + path_parts.join("/")
        u += '.html' unless u =~ /\.\w{2,4}$/
        u
      end
      alias_method :u, :url
    end

    class << self
      attr_accessor :configuration
    end
    
    def configuration
      self.class.configuration || {}
    end

    def initialize
      super
      if configuration['store']
        store_class = configuration['store']['class'].split('::').inject(Object) {|mod, string| mod.const_get(string)}
        self.store = store_class.new(*Array(configuration['store']['parameters']))
      else
        self.store = ExceptionLogger::Store::InMemory.new
      end
    end
    
    get '/' do
      erb :index
    end

    get '/search' do
      erb :search
    end
    
    post '/search' do
      puts params.inspect
      @results = store.search(params)
      erb :search
    end
    
    get '/similar/:digest.html' do
      @group = store.group(params[:digest])
      if @group
        erb :similar
      else
        404
      end
    end
    
    get '/exceptions/:id.html' do
      @report = store.find(params[:id])
      if @report
        @group = store.group(@report.digest)
        erb :show
      else
        404
      end
    end

    post '/report.json' do
      report = ExceptionLogger::ExceptionReport.new(JSON.parse(request.body.read))
      store.store(report)
      200
    end
    
  end
end
