# The base Exceptionl::Plugin, that all plugins should inherit
# from. Provides default implementations of all the supported plugin
# methods, so you can (and should) call +super+ in your plugin subclasses.
class Exceptionl::Plugin::Base

  # Create a new instance of this plugin. +app+ is the sinatra
  # Exceptionl::Server instance, and +params+ is an arbitrary hash of
  # plugin-specific parameters or options.
  def initialize(app, params = {})
  end
  
  # An array of [name, href] pairs of links that will show up on the
  # exception detail page. These are most commonly used to link to
  # additional routes added by the plugin.
  def exception_links(exception_report)
    []
  end

  # Called after a new exception is reported. At the point that this
  # is called, +exception_report+ will have an ID and has been
  # associated with an exception group.
  def after_create(app, exception_report)
  end
end
