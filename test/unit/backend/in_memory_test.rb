require 'test_helper'
require 'error_stalker/backend/in_memory'

class BackendInMemoryTest < Test::Unit::TestCase

  def setup
    super
    @backend = ErrorStalker::Backend::InMemory.new
    @exception_report = ErrorStalker::ExceptionReport.new(:application => :unit_test, :exception => 'Test Exception')
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
