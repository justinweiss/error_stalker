require 'test_helper'
require 'exceptionl/backend/in_memory'

class BackendInMemoryTest < Test::Unit::TestCase

  def setup
    super
    @backend = Exceptionl::Backend::InMemory.new
    @exception_report = Exceptionl::ExceptionReport.new(:application => :unit_test, :exception => 'Test Exception')
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
