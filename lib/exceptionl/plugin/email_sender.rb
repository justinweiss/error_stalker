require 'mail'

class Exceptionl::Plugin::EmailSender < Exceptionl::Plugin::Base

  attr_reader :mail_params
  
  def initialize(app, params = {})
    @mail_params = params
  end

  # Builds the mail object from +exception_report+ that we can later
  # deliver. This is mostly here to make testing easier.
  def build_email(exception_report, exception_url)
    @report = exception_report
    @url = exception_url
    
    mail = Mail.new({
        'subject' => "Exception #{exception_report.machine} - #{exception_report.exception.to_s[0, 64]}",
        'body' => ERB.new(File.read(File.expand_path('views/exception_email.erb', File.dirname(__FILE__)))).result(binding)
      }.merge(mail_params))

    if mail_params['delivery_method']
      mail.delivery_method mail_params['delivery_method'].to_sym, mail_params['delivery_settings'] || {}
    end
    
    mail
  end

  # Optionally send a mail if it's the first time we've seen this
  # report
  def send_email(app, exception_report)
    request = app.request
    url = "#{request.scheme}://#{request.host}:#{request.port}/exceptions/#{exception_report.id}.html"
    mail = build_email(exception_report, url)
    mail.deliver
  end
  
  def after_create(app, report)
    # Only send an email if it's the first exception of this type
    # we've seen
    send_email(app, report) if app.store.group(report.digest).count == 1
  end

end
