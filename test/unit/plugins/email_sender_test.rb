require 'test_helper'

class EmailSenderTest < Test::Unit::TestCase

  def test_email_configuration_with_strings
    p = ErrorStalker::Plugin::EmailSender.new(nil, {'to' => nil, 'from' => nil, 'delivery_method' => 'sendmail'})
    e = ErrorStalker::ExceptionReport.new(:exception => 'test', :application => 'test', :data => {})
    mail = p.build_email(e, nil)
    assert_equal Mail::Sendmail, mail.delivery_method.class
  end
end

