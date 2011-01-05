require 'mongoid'
require 'exception_logger/store/base'

# Store exceptions using MongoDB. This store provides fast storage and
# querying of exceptions, and long-term persistence.
class ExceptionLogger::Store::Mongoid < ExceptionLogger::Store::Base
  
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
    ExceptionReport.create_from_exception_report(exception_report)
  end

  # Have we logged any exceptions?
  def empty?
    ExceptionReport.count == 0
  end

  # Return the last +limit+ unique exception reports that have been reported.
  def recent
    ExceptionReport.recent
  end

  # Find an exception report with the given id.
  def find(id)
    ExceptionReport.find(id)
  end

  # All applications that have been seen in this report
  def applications
    ExceptionReport.applications
  end

  # All machines that have seen this exception
  def machines
    ExceptionReport.machines
  end
  
  # returns the group this exception is a part of, ordered by
  # timestamp
  def group(digest)
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
        scope.where("data.#{key}" => /#{value}/)
      end
    end
    
    scope
  end
end

# The mongoid version of ExceptionLogger::ExceptionReport. This class
# is used for mongo-specific querying and persistence of
# ExceptionReports, while base ExceptionReports are store-agnostic.
class ExceptionLogger::Store::Mongoid::ExceptionReport
  include Mongoid::Document
  field :application
  field :machine
  field :timestamp, :type => Time
  field :type
  field :exception
  field :data, :type => Hash
  field :backtrace
  field :digest

  # Create a new mongoid exception report from +exception_report+.
  def self.create_from_exception_report(exception_report)
    new do |o|
      [:application, :machine, :timestamp, :type, :exception, :data, :digest].each do |field|
        o.send("#{field}=", exception_report.send(field))
      end
      if exception_report.backtrace
        o.backtrace = exception_report.backtrace.join("\n")
      end
    end.save
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
    
    results.find.map {|v| [v["value"]["count"], new(v["value"]["most_recent"])]}
  end
end
