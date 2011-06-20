require 'mongoid'
require 'exceptionl/store/base'

# Store exceptions using MongoDB. This store provides fast storage and
# querying of exceptions, and long-term persistence. It also allows
# querying based on arbitrary data stored in the +data+ hash of the
# exception report, which allows for crazy things like searching
# reports by URL or IP address. 
class Exceptionl::Store::Mongoid < Exceptionl::Store::Base
  
  # Configure mongoid from the mongoid config file found in
  # +config_file+. This mongoid config file should be similar to the
  # one on http://mongoid.org/docs/installation/, and must be indexed
  # by environment name. +config_file+ is relative to either wherever
  # you start the server from or the config.ru file, unless you pass a
  # full file path.
  def initialize(config_file)
    filename = File.expand_path(config_file)
    settings = YAML.load(ERB.new(File.new(filename).read).result)

    Mongoid.configure do |config|
      config.from_hash(settings[ENV['RACK_ENV']])
    end
    Thread.new { migrate_data }
  end

  # Store +exception_report+ in the database.
  def store(exception_report)
    report = ExceptionReport.create_from_exception_report(exception_report)
    update_caches(report)
    report.id
  end

  # Have we logged any exceptions?
  def empty?
    ExceptionGroup.where(:most_recent_timestamp.gt => 7.days.ago).count == 0
  end

  # Return the last 7 days worth of unique exception reports grouped
  # by exception group.
  def recent
    # Needs to be wrapped in a PaginationHelper because we'll call
    # paginate on the collection returned from this method. We don't
    # want to use mongoid pagination here because we don't know what
    # parameters we want to paginate on, and we don't want to return
    # an array here because we don't want to load all the mongid
    # models in memory. This is also made trickier because of my
    # hacked-up :include stuff I built into ExceptionGroup.
    ExceptionGroup::PaginationHelper.new(ExceptionGroup.where(:most_recent_timestamp.gt => 7.days.ago).order_by(:most_recent_timestamp.desc))
  end

  # Find an exception report with the given id.
  def find(id)
    ExceptionReport.find(id).to_exception_report
  end

  # All applications that have been seen by this store
  def applications
    Application.all.order_by(:name.asc).map(&:name)
  end

  # All machines that have been seen by this store
  def machines
    Machine.all.order_by(:name.asc).map(&:name)
  end

  # Returns all the exceptions in a group, ordered by
  # most_recent_timestamp
  def reports_in_group(digest)
    ExceptionReport.where(:digest => digest).order_by(:timestamp.desc)
  end
  
  # returns the ExceptionGroup object corresponding to a particular
  # digest
  def group(digest)
    ExceptionGroup.where(:digest => digest).first
  end

  # Does this store support searching through the data blob?
  def supports_extended_searches?
    true
  end
  
  def total
    ExceptionReport.count()
  end
  
  def total_since(timestamp)
    ExceptionReport.where(:timestamp.gte => timestamp).count()
  end

  # Searches for exception reports maching +params+. Supports querying
  # by arbitrary data in the +data+ hash associated with the exception, with the format:
  #
  # REMOTE_ADDR:127.0.0.1 PATH:/test
  def search(params)
    scope = ExceptionReport.all

    [:application, :machine].each do |param|
      if params[param] && !params[param].empty?
        scope.where(param => params[param])
      end
    end

    [:exception, :type].each do |param|
      if params[param] && !params[param].empty?
        scope.where(param => /#{params[param]}/)
      end
    end

    if params[:data] && !params[:data].empty?
      params[:data].split.each do |keyvalue|
        key, value = keyvalue.split(':')
        scope.where("data" => {"#{key}" => "#{value}"})
      end
    end
    
    scope.order_by(:timestamp.desc)
  end

  # Creates the MongoDB indexes used by this driver. Should be called
  # at some point after deciding to use the mongoid store. Can be
  # called either manually, or by running <tt>bin/create_indexes</tt>
  def create_indexes
    Exceptionl::Store::Mongoid::ExceptionReport.create_indexes
    Exceptionl::Store::Mongoid::ExceptionGroup.create_indexes
  end

  # Migrate the data in the mongoid database to a newer format. This
  # should eventually be more robust, like the Rails version, but for
  # now this should be fine.
  def migrate_data
    if SchemaMigrations.where(:version => 1).empty?
      ExceptionGroup.all.order_by(:timestamp).desc.each do |group|
        exceptions = ExceptionReport.where(:digest => group.digest).order_by(:timestamp)
        unless exceptions.empty?
          exceptions = exceptions.to_a
          group.attributes[:timestamp] = nil
          group.first_timestamp = exceptions[0].timestamp
          group.most_recent_timestamp = exceptions[-1].timestamp
          group.machines = exceptions.map(&:machine).uniq
          group.save
        end
      end
      SchemaMigrations.create(:version => 1)
    end
  end

  protected

  # In order to make Exceptionl super-fast, we keep a bunch of cached
  # data (like exception report groups, machines, and
  # applications). +update_caches+ updates all of this cached data
  # when an exception report comes in.
  def update_caches(report)
    ExceptionGroup.collection.update(
      {:digest => report.digest},
      {
        '$inc' => {:count => 1},
        '$set' => {:most_recent_report_id => report.id, :most_recent_timestamp => report.timestamp},
        '$addToSet' => {:machines => report.machine}
      },
      :upsert => true)

    # Make sure the first_timestamp parameter is set. Unfortunately
    # mongoid doesn't have an $add modifier yet, so we have to do another query.
    ExceptionGroup.collection.update(
      {:digest => report.digest, :first_timestamp => nil},
      {'$set' => {:first_timestamp => report.timestamp}})

    # Update indexes to pre-populate the search dropdowns.
    Machine.collection.update(
      {:name => report.machine},
      {:name => report.machine},
      :upsert => true)
    
    Application.collection.update(
      {:name => report.application},
      {:name => report.application},
      :upsert => true)
    
    report.id
  end
end

# Keeps track of the migrations we've run so far.
class Exceptionl::Store::Mongoid::SchemaMigrations
  include Mongoid::Document
  field :version
end

# A cache of all the applications that have had exception reports seen
# by this server, so we don't have to search the entire DB to populate
# the search dropdown.
class Exceptionl::Store::Mongoid::Application
  include Mongoid::Document
  field :name
end

# A cache of all the machines that have had exception reports seen by
# this server, so we don't have to search the entire DB to populate
# the search dropdown.
class Exceptionl::Store::Mongoid::Machine
  include Mongoid::Document
  field :name
end

# Aggregates exceptions for for the 'recent exceptions' list. This is
# way faster than mapreducing on demand, although it requires some
# crazy code to preload all the exceptions.
class Exceptionl::Store::Mongoid::ExceptionGroup < Exceptionl::ExceptionGroup
  include Mongoid::Document
  field :count, :type => Integer
  field :digest
  field :machines, :type => Array
  field :first_timestamp, :type => Time
  field :most_recent_timestamp, :type => Time
  field :most_recent_report_id, :type => Integer
  index :digest
  index :most_recent_timestamp

  # Cache most recent report so we can preload a bunch at once
  attr_accessor :most_recent_report

  # When we display the list of grouped recent exceptions, we paginate
  # them. We also need to display information about the most recent
  # exception report. This helper class wraps +paginate+, doing a
  # hacked-in +:include+ to get the most recent reports for the requested
  # exception groups without running into the N+1 problem.
  class PaginationHelper

    # Wraps +criteria+ in a new PaginationHelper, which will include
    # the most recent exception reports when +paginate+ is called.
    def initialize(criteria)
      @criteria = criteria
    end

    # Override the built-in pagination to support preloading the
    # associated exception reports.
    def paginate(pagination_opts = {})
      recent = @criteria.paginate(pagination_opts)
      exceptions = Exceptionl::Store::Mongoid::ExceptionReport.where(:_id.in => recent.map(&:most_recent_report_id))
      # Fake association preloading
      id_map = {}.tap do |h|
        exceptions.each do |ex|
          h[ex.id] = ex
        end
      end
      
      recent.each do |r|
        r.most_recent_report = id_map[r.most_recent_report_id]
      end
      
      recent
    end
  end
end

# The mongoid version of Exceptionl::ExceptionReport. This class
# is used for mongo-specific querying and persistence of
# ExceptionReports, while base ExceptionReports are store-agnostic.
class Exceptionl::Store::Mongoid::ExceptionReport
  include Mongoid::Document
  field :application
  field :machine
  field :timestamp, :type => Time
  field :type
  field :exception
  field :data, :type => Array
  field :backtrace, :type => Array
  field :digest

  index :digest
  index :data
  index :timestamp

  # Generates an Exceptionl::ExceptionReport from this model,
  # converting the +data+ field from a list of key-value pairs to a
  # full-fledged hash. Internally, we store it as a list of key->value
  # to support fast multiattribute indexing, one of the cooler mongo
  # features.
  def to_exception_report
    params = {}
    [:id, :application, :machine, :timestamp, :type, :exception, :digest, :backtrace].each do |field|
      params[field] = send(field)
    end
    
    if data
      params[:data] = {}.tap do |h|
        data.map { |hash| h[hash.keys.first] = hash[hash.keys.first] }
      end
    end
    
    Exceptionl::ExceptionReport.new(params)
  end
  
  # Create a new mongoid exception report from +exception_report+.
  def self.create_from_exception_report(exception_report)
    object = new do |o|
      [:application, :machine, :timestamp, :type, :exception, :digest].each do |field|
        o.send("#{field}=", exception_report.send(field))
      end

      # Store data as a list of key-value pairs, so the index on 'data' catches them all
      if exception_report.data && exception_report.data.kind_of?(Hash)
        o.data = [].tap do |array|
          exception_report.data.map {|key, value| array << {key => value}}
        end
      end
      
      if exception_report.backtrace
        o.backtrace = exception_report.backtrace
      end
    end
    object.save
    object
  end
end
