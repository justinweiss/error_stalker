require 'sinatra/base'

$: << File.expand_path('..', File.dirname(__FILE__))
require 'exceptionl'
require 'exceptionl/store'
require 'exceptionl/plugin'
require 'erb'
require 'will_paginate'
require 'will_paginate/view_helpers/base'
require 'exceptionl/sinatra_link_renderer'

module Exceptionl
  # The exceptionl server. Provides a UI for browsing, grouping,
  # and searching exception reports.
  class Server < Sinatra::Base

    # The number of exceptions or exception groups to show on each
    # page.
    PER_PAGE = 25
  
    attr_accessor :store # The data store (Exceptionl::Store instance)
                         # to use to store exception data
    attr_accessor :plugins # A list of plugins the server will use.
    
    set :root, File.dirname(__FILE__)
    set :public, Proc.new { File.join(root, "server/public") }
    set :views, Proc.new { File.join(root, "server/views") }

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html

      include WillPaginate::ViewHelpers::Base
      
      def url(*path_parts)
        u = '/' + path_parts.join("/")
        u += '.html' unless u =~ /\.\w{2,4}$/
        u
      end
      alias_method :u, :url

      def cutoff(str, limit = 100)
        if str.length > limit
          str[0, limit] + '...'
        else
          str
        end
      end
    end

    class << self
      attr_accessor :configuration # A hash of configuration options,
                                   # usually read from a configuration
                                   # file.
    end
    self.configuration = {}

    # The default Exceptionl::Store subclass to use by default for
    # this Exceptionl::Server instance. This is defined as a class
    # method as well as an instance method so that it can be set by a
    # configuration file before rack creates the instance of this
    # sinatra app.
    def self.store
      if configuration['store']
        store_class = configuration['store']['class'].split('::').inject(Object) {|mod, string| mod.const_get(string)}
        store_class.new(*Array(configuration['store']['parameters']))
      else
        Exceptionl::Store::InMemory.new
      end
    end

    # A hash of configuration options, usually read from a
    # configuration file.
    def configuration
      self.class.configuration
    end

    # Creates a new instance of the server, based on the configuration
    # contained in the +configuration+ attribute.
    def initialize
      super
      self.plugins = []
      if configuration['plugin']
        configuration['plugin'].each do |config|
          plugin_class = config['class'].split('::').inject(Object) {|mod, string| mod.const_get(string)}
          self.plugins << plugin_class.new(self, config['parameters'])
        end
      end
      self.store = self.class.store
    end
    
    get '/' do
      @records = store.recent.paginate(:page => params[:page], :per_page => PER_PAGE)
      erb :index
    end

    get '/search' do
      @results = store.search(params).paginate(:page => params[:page], :per_page => PER_PAGE) if params["Search"]
      erb :search
    end
    
    get '/similar/:digest.html' do
      @group = store.group(params[:digest]).paginate(:page => params[:page], :per_page => PER_PAGE)
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
      plugins.each {|p| p.after_create(self, report)}
      200
    end
    
  end
end
