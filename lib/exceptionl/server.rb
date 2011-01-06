require 'sinatra/base'

$: << File.expand_path('..', File.dirname(__FILE__))
require 'exceptionl'
require 'exceptionl/store'
require 'erb'
require 'pony'

module Exceptionl

  # The exceptionl server. Provides a UI for browsing, grouping,
  # and searching exception reports.
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

    # Optionally send a mail if it's the first time we've seen this
    # report
    def send_email(exception_report)
      if configuration['email']
        @report = exception_report
        Pony.mail(:to => configuration['email']['to'],
          :from => configuration['email']['from'],
          :subject => "Exception #{exception_report.machine} - #{exception_report.exception.to_s[0, 64]}",
          :body => erb(:exception_email))
      end
    end

    def initialize
      super
      if configuration['store']
        store_class = configuration['store']['class'].split('::').inject(Object) {|mod, string| mod.const_get(string)}
        self.store = store_class.new(*Array(configuration['store']['parameters']))
      else
        self.store = Exceptionl::Store::InMemory.new
      end
    end
    
    get '/' do
      erb :index
    end

    get '/search' do
      erb :search
    end
    
    post '/search' do
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
      report = Exceptionl::ExceptionReport.new(JSON.parse(request.body.read))
      report.id = store.store(report)

      # Only send an email if it's the first exception of this type
      # we've seen
      send_email(report) if store.group(report.digest).count == 1
      200
    end
    
  end
end