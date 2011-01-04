require 'test_helper'
require 'exception_logger/backends/in_memory'

class BackendsInMemoryTest < Test::Unit::TestCase

  def setup
    super
    @backend = ExceptionLogger::Backends::InMemory.new
    @exception_report = ExceptionLogger::ExceptionReport.new(:application => :unit_test, :exception => 'Test Exception')
  end
  
  def test_report_is_implemented
    @backend.report(@exception_report)
    assert_equal 1, @backend.exceptions.length
  end

  def test_clear_is_implemented
    @backend.report(@exception_report)
    @backend.clear
    assert_equal 0, @backend.exceptions.length
  end
end
