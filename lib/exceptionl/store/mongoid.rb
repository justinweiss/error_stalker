require 'mongoid'
require 'exceptionl/store/base'

# Store exceptions using MongoDB. This store provides fast storage and
# querying of exceptions, and long-term persistence.
class Exceptionl::Store::Mongoid < Exceptionl::Store::Base
  
  # Configure mongoid from the mongoid config file found in
  # +config_file+.
  def initialize(config_file)
    filename = File.expand_path(config_file)
    settings = YAML.load(ERB.new(File.new(filename).read).result)

    Mongoid.configure do |config|
      config.from_hash(settings[ENV['RACK_ENV']])
    end
  end

  # Store +exception_report+ in the exception list
  def store(exception_report)
    report = ExceptionReport.create_from_exception_report(exception_report)

    ExceptionGroup.collection.update(
      {:digest => report.digest},
      {
        '$inc' => {:count => 1},
        '$set' => {:most_recent_report_id => report.id, :timestamp => report.timestamp},
      },
      :upsert => true)

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

  # Have we logged any exceptions?
  def empty?
    ExceptionGroup.where(:timestamp.gt => 7.days.ago).count == 0
  end

  # Return the last 7 days worth of unique exception reports grouped by exception group.
  def recent
    ExceptionGroup::PaginationHelper.new(ExceptionGroup.where(:timestamp.gt => 7.days.ago).order_by(:timestamp.desc))
  end

  # Find an exception report with the given id.
  def find(id)
    ExceptionReport.find(id).to_exception_report
  end

  # All applications that have been seen by this store
  def applications
    Application.all.map(&:name)
  end

  # All machines that have been seen by this store
  def machines
    Machine.all.map(&:name)
  end

  # returns the group this exception is a part of, ordered by
  # timestamp
  def group(digest, params = {})
    ExceptionReport.where(:digest => digest).order_by(:timestamp.desc)
  end

  # Searches for exception reports maching +params+.
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

  # Creates the MongoDB indexes used by this driver.
  def create_indexes
    Exceptionl::Store::Mongoid::ExceptionReport.create_indexes
    Exceptionl::Store::Mongoid::ExceptionGroup.create_indexes
  end
end

# A cache of all the applications that have been seen by this server,
# so we don't have to search the entire DB to populate the search
# dropdown.
class Exceptionl::Store::Mongoid::Application
  include Mongoid::Document
  field :name
end

# A cache of all the machines that have been seen by this server,
# so we don't have to search the entire DB to populate the search
# dropdown.
class Exceptionl::Store::Mongoid::Machine
  include Mongoid::Document
  field :name
end

# Aggregates exceptions for for the 'recent exceptions' list. This is
# way faster than mapreducing on demand.
class Exceptionl::Store::Mongoid::ExceptionGroup < Exceptionl::ExceptionGroup
  include Mongoid::Document
  field :count, :type => Integer
  field :digest
  field :timestamp, :type => Time
  field :most_recent_report_id, :type => Integer
  index :digest
  index :timestamp

  # Cache most recent report so we can preload a bunch at once
  attr_accessor :most_recent_report

  # When we display the list of grouped recent exceptions, we paginate
  # them. We also need to display information about the most recent
  # exception report. This helper class wraps +paginate+, including
  # the most recent reports for the requested exception groups.
  class PaginationHelper

    def initialize(criteria)
      @criteria = criteria
    end

    # Override pagination to support preloading the exception reports
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
  # full-fledged hash.
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
