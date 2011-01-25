require 'mail'

# The email sender plugin will send an email to an address the first
# time an exception in a group is reported. Future exceptions that go
# in the same group will not trigger emails.
class Exceptionl::Plugin::EmailSender < Exceptionl::Plugin::Base

  # Parameters that are used in order to figure out how and where to
  # send the report email. These parameters are passed directly to the
  # {mail gem}[https://github.com/mikel/mail]. See that page for a
  # reference. The subject and body are created by the plugin, but all
  # other parameters (to, from, etc.) will have to be passed in.
  attr_reader :mail_params

  # Create a new instance of this plugin. +mail_params+ is a hash of
  # parameters that are used to build the report email.
  def initialize(app, mail_params = {})
    super(app, mail_params)
    @mail_params = mail_params
  end

  # Builds the mail object from +exception_report+ that we can later
  # deliver. This is mostly here to make testing easier.
  def build_email(exception_report, exception_url)
    @report = exception_report
    @url = exception_url
    
    mail = Mail.new({
        'subject' => "Exception on #{exception_report.machine} - #{exception_report.exception.to_s[0, 64]}",
        'body' => ERB.new(File.read(File.expand_path('views/exception_email.erb', File.dirname(__FILE__)))).result(binding)
      }.merge(mail_params))

    if mail_params['delivery_method']
      mail.delivery_method(mail_params['delivery_method'].to_sym, (mail_params['delivery_settings'] || {}))
    end
    
    mail
  end

  # Sets up the parameters we need to build a new exception report
  # email, and sends the mail.
  def send_email(app, exception_report)
    request = app.request
    host_with_port = request.host
    host_with_port << ":#{request.port}" if request.port != 80
    url = "#{request.scheme}://#{host_with_port}/exceptions/#{exception_report.id}.html"
    mail = build_email(exception_report, url)
    mail.deliver
  end

  # Hook to trigger an email when a new exception report with
  # +report+'s digest comes in.
  def after_create(app, report)
    # Only send an email if it's the first exception of this type
    # we've seen
    send_email(app, report) if app.store.group(report.digest).count == 1
    super(app, report)
  end

end
