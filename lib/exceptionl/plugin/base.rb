# Base exceptionl plugin.
class Exceptionl::Plugin::Base
  # An array of [name, href] pairs of links that should show up on the
  # exceptions/show page.
  def exception_links
    []
  end
end
