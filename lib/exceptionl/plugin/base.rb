# Base exceptionl plugin.
class Exceptionl::Plugin::Base
  # An array of [name, href] pairs of links that should show up on the
  # exceptions/show page.
  def exception_links
    []
  end

  # Called after a new exception is reported
  def after_create(app, exception_report)
  end
end
