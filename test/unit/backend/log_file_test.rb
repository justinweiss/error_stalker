require 'test_helper'
require 'error_stalker/backend/log_file'
require 'tempfile'

class BackendLogFileTest < Test::Unit::TestCase

  def setup
    super
    filename = File.join(Dir.tmpdir, 'exceptions.log')
    @backend = ErrorStalker::Backend::LogFile.new(filename)
    @exception_report = ErrorStalker::ExceptionReport.new(:application => :unit_test, :exception => 'Test Exception', :data => {:name => 'Bob'})
  end

  def teardown
    File.delete(@backend.filename) if File.exists?(@backend.filename)
    super
  end
  
  def test_report_is_implemented
    @backend.report(@exception_report)
    exception_string = File.read(@backend.filename)
    assert_match /Application: unit_test/, exception_string
    assert_match /Exception: Test Exception/, exception_string
  end
end
