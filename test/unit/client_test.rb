require 'test_helper'
require 'exception_logger/backends/in_memory'

class ClientTest < Test::Unit::TestCase

  def setup
    super
    @backend = ExceptionLogger::Backends::InMemory.new
    ExceptionLogger::Client.backend = @backend
  end
  
  def test_report
    ExceptionLogger::Client.report(:unit_test, new_exception, {:name => "Bob"})

    assert_equal 1, @backend.exceptions.length
    exception_report = @backend.exceptions.first
    assert_equal :unit_test, exception_report.application
    assert_equal exception_report.send(:machine_name), exception_report.machine
    assert_match "test/unit/client_test.rb:", exception_report.backtrace.first
    assert_equal 'Bob', exception_report.data[:name]
    assert_equal 'NoMethodError', exception_report.type
  end

  def test_report_exceptions_in_block
    ExceptionLogger::Client.report_exceptions(:unit_test) do
      raise new_exception
    end

    assert_equal 1, @backend.exceptions.length
  end

  def test_dont_raise_exceptions_during_report
    ExceptionLogger::Client.backend = nil
    
    assert_nothing_raised do
      ExceptionLogger::Client.report(:unit_test, new_exception, {:name => "Bob"})
    end
  end

  def new_exception
    exception = nil
    begin
      nil.foo
    rescue => e
      exception = e
    end
    exception
  end
end
