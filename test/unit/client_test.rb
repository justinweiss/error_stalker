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
