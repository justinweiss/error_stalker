# Base exceptionl plugin.
class Exceptionl::Plugin::Base

  # Create a new instance of this plugin. +app+ is the sinatra server
  # instance, and +params+ is an arbitrary hash of parameters or
  # options.
  def initialize(app, params = {})
  end
  
  # An array of [name, href] pairs of links that should show up on the
  # exceptions/show page.
  def exception_links(exception_report)
    []
  end

  # Called after a new exception is reported
  def after_create(app, exception_report)
  end
end
