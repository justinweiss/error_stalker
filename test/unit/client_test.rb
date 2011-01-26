require 'test_helper'
require 'exceptionl/backend/in_memory'

class ClientTest < Test::Unit::TestCase

  def setup
    super
    @backend = Exceptionl::Backend::InMemory.new
    Exceptionl::Client.backend = @backend
  end
  
  def test_report
    Exceptionl::Client.report(:unit_test, new_exception, {:name => "Bob"})

    assert_equal 1, @backend.exceptions.length
    exception_report = @backend.exceptions.first
    assert_equal :unit_test, exception_report.application
    assert_equal exception_report.send(:machine_name), exception_report.machine
    assert_match "test/unit/client_test.rb:", exception_report.backtrace.first
    assert_equal 'Bob', exception_report.data[:name]
    assert_equal 'NoMethodError', exception_report.type
  end

  def test_report_exceptions_in_block
    assert_raises NoMethodError do 
      Exceptionl::Client.report_exceptions(:unit_test) do
        raise new_exception
      end

      assert_equal 1, @backend.exceptions.length
    end
  end

  def test_report_exceptions_in_block_without_reraise
    assert_nothing_raised do
      Exceptionl::Client.report_exceptions(:unit_test, :reraise => false) do
        raise new_exception
      end

      assert_equal 1, @backend.exceptions.length

      Exceptionl::Client.report_exceptions(:unit_test, :reraise => nil) do
        raise new_exception
      end

      assert_equal 2, @backend.exceptions.length
    end
  end

  def test_dont_raise_exceptions_during_report
    Exceptionl::Client.backend = nil
    
    assert_nothing_raised do
      Exceptionl::Client.report(:unit_test, new_exception, {:name => "Bob"})
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
