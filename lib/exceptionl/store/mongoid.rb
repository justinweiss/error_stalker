require 'mongoid'
require 'exceptionl/store/base'

# Store exceptions using MongoDB. This store provides fast storage and
# querying of exceptions, and long-term persistence.
class Exceptionl::Store::Mongoid < Exceptionl::Store::Base
  PER_PAGE = 50
  
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
    RecentException.collection.update(
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
    RecentException.where(:timestamp.gt => 7.days.ago).count == 0
  end

  # Return the last +limit+ unique exception reports that have been reported.
  def recent(params = {})
    recent = RecentException.where(:timestamp.gt => 7.days.ago).order_by(:timestamp.desc).paginate(:page => params[:page], :per_page => PER_PAGE)

    exceptions = ExceptionReport.where(:_id.in => recent.map(&:most_recent_report_id))
    
    # Fake association preloading
    id_map = {}.tap do |h|
      exceptions.each do |ex|
        h[ex.id] = ex
      end
    end

    WillPaginate::Collection.create(recent.current_page, recent.per_page, recent.total_entries) do |pager|
      pager.replace(recent.map {|r| [r.count, id_map[r.most_recent_report_id]]})
    end
  end

  # Find an exception report with the given id.
  def find(id)
    ExceptionReport.find(id)
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
    ExceptionReport.where(:digest => digest).order_by(:timestamp.desc).paginate(:page => params[:page], :per_page => PER_PAGE)
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
        scope.where("data.#{key}" => /#{value}/)
      end
    end
    
    scope.order_by(:timestamp.desc).paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  # Creates the MongoDB indexes used by this driver.
  def create_indexes
    Exceptionl::Store::Mongoid::ExceptionReport.create_indexes
    Exceptionl::Store::Mongoid::RecentExceptions.create_indexes
  end
end

class Exceptionl::Store::Mongoid::Application
  include Mongoid::Document
  field :name
end

class Exceptionl::Store::Mongoid::Machine
  include Mongoid::Document
  field :name
end

# Aggregates exceptions for for the 'recent exceptions' list.
class Exceptionl::Store::Mongoid::RecentException
  include Mongoid::Document
  field :count, :type => Integer
  field :ordinal
  field :timestamp, :type => Time
  index :ordinal
  index :timestamp
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
  field :data, :type => Hash
  field :backtrace
  field :digest

  index :digest
  index :data
  index :timestamp

  # Create a new mongoid exception report from +exception_report+.
  def self.create_from_exception_report(exception_report)
    object = new do |o|
      [:application, :machine, :timestamp, :type, :exception, :data, :digest].each do |field|
        o.send("#{field}=", exception_report.send(field))
      end
      
      if exception_report.backtrace
        o.backtrace = exception_report.backtrace.join("\n")
      end
    end
    object.save
    object
  end

  def self.applications
    map = <<EOS
function() {
  emit(this.application, {});
}
EOS

    reduce = <<EOS
function(key, vals) {
  return key;
}
EOS
    results = collection.map_reduce(map, reduce, :out => :applications)
    results.find.map {|v| v['value']}
  end

   def self.machines
    map = <<EOS
function() {
  emit(this.machine, {});
}
EOS

    reduce = <<EOS
function(key, vals) {
  return key;
}
EOS
    results = collection.map_reduce(map, reduce, :out => :machines)
    results.find.map {|v| v['value']}
  end
  
  # Return the most recent exceptions, in a list of <tt>[count,
  # most_recent_exception]</tt> elements.
  def self.recent
    map = <<EOS
function() {
  emit(this.digest, {count: 1, most_recent: this});
}
EOS

    reduce = <<EOS
function(key, vals) {
  var most_recent = vals[0].most_recent;
  var most_recent_timestamp = vals[0].most_recent.timestamp;
  var count = 0;
  vals.forEach(function(doc) {
    count += doc.count;
    if(most_recent_timestamp < doc.most_recent.timestamp) {
      most_recent = doc.most_recent;
      most_recent_timestamp = doc.most_recent.timestamp;
    }
  });
  return {count: count, most_recent: most_recent};
}
EOS
    results = collection.map_reduce(map, reduce, {:query => {:timestamp => {"$gt" => 7.days.ago}}, :out => :grouped_exceptions})
    
    results.find.sort(['value.most_recent.timestamp', 'descending']).map {|v| [v["value"]["count"], new(v["value"]["most_recent"])]}
  end
end
