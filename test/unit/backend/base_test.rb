require 'test_helper'

class BackendBaseTest < Test::Unit::TestCase
  def test_report_is_not_implemented
    assert_raises NotImplementedError do
      Exceptionl::Backend::Base.new.report("foo")
    end
  end
end
