require 'sinatra/base'

$: << File.expand_path('..', File.dirname(__FILE__))
require 'error_stalker'
require 'error_stalker/store'
require 'error_stalker/plugin'
require 'erb'
require 'will_paginate'
require 'error_stalker/version'

module ErrorStalker
  # The ErrorStalker server. Provides a UI for browsing, grouping, and
  # searching exception reports, as well as a centralized store for
  # keeping exception reports. As a Sinatra app, this can be run using
  # a config.ru file or something like Vegas. A sample Vegas runner
  # for the server is located in <tt>bin/error_stalker_server</tt>.
  class Server < Sinatra::Base

    # The number of exceptions or exception groups to show on each
    # page.
    PER_PAGE = 25

    # The data store (ErrorStalker::Store instance) to use to store
    # exception data
    attr_accessor :store

    # A list of plugins the server will use.
    attr_accessor :plugins

    set :root, File.dirname(__FILE__)
    set :public, Proc.new { File.join(root, "server/public") }
    set :views, Proc.new { File.join(root, "server/views") }

    register WillPaginate::Sinatra

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html

      # Generates a url from an array of strings representing the
      # parts of the path.
      def url(*path_parts)
        u = '/' + path_parts.join("/")
        u += '.html' unless u =~ /\.\w{2,4}$/
        u
      end
      alias_method :u, :url

      # Cuts +str+ at +limit+ characters. If +str+ is too long, will
      # apped '...' to the end of the returned string.
      def cutoff(str, limit = 100)
        if str.length > limit
          str[0, limit] + '...'
        else
          str
        end
      end
    end

    class << self
      # A hash of configuration options, usually read from a
      # configuration file.
      attr_accessor :configuration
    end
    self.configuration = {}

    # The default ErrorStalker::Store subclass to use by default for
    # this ErrorStalker::Server instance. This is defined as a class
    # method as well as an instance method so that it can be set by a
    # configuration file before rack creates the instance of this
    # sinatra app.
    def self.store
      if configuration['store']
        store_class = configuration['store']['class'].split('::').inject(Object) {|mod, string| mod.const_get(string)}
        store_class.new(*Array(configuration['store']['parameters']))
      else
        ErrorStalker::Store::InMemory.new
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
      @group = store.reports_in_group(params[:digest]).paginate(:page => params[:page], :per_page => PER_PAGE)
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

    get '/stats.json' do
      timestamp = Time.at(params[:timestamp].to_i) if params[:timestamp]
      # default to 1 hour ago
      timestamp ||= Time.now - (60*60)
      stats = {}
      stats[:timestamp] = timestamp.to_i
      stats[:total_since] = store.total_since(timestamp)
      stats[:total] = store.total
      stats[:version] = ErrorStalker::VERSION
      stats.to_json
    end

    post '/report.json' do
      report = ErrorStalker::ExceptionReport.new(JSON.parse(request.body.read))
      report.id = store.store(report)
      plugins.each {|p| p.after_create(self, report)}
      200
    end

  end
end
