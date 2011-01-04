require 'test_helper'

class ExceptionReportTest < Test::Unit::TestCase

  def test_serialization
    original_report = ExceptionLogger::ExceptionReport.new(:application => :unit_test, :exception => NoMethodError.new, :data => {:name => "Bob"})

    exception_report = ExceptionLogger::ExceptionReport.new(JSON.parse(original_report.to_json))
    
    assert_equal 'unit_test', exception_report.application
    assert_equal exception_report.send(:machine_name), exception_report.machine
    assert_equal 'Bob', exception_report.data['name']
    assert_equal 'NoMethodError', exception_report.type
  end
end
