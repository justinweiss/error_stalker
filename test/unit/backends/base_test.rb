require 'test_helper'

class BackendsBaseTest < Test::Unit::TestCase
  def test_report_is_not_implemented
    assert_raises NotImplementedError do
      ExceptionLogger::Backends::Base.new.report("foo")
    end
  end
end
