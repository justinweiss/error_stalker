# The Exceptionl server supports third-party plugins that add
# functionality to the server.
#
# Plugins should inherit from Exceptionl::Plugin::Base. This base
# plugin provides functions that can be overridden in its
# children. Currently, a few hooks are provided for plugins to
# override:
#
# [Exceptionl::Plugin::Base.new] Called when the server starts. This
#                                method can be overridden to do things
#                                like add extra routes to the server
#                                or initialize any data structures
#                                that the plugin needs to keep track
#                                of. Take a look at
#                                Exceptionl::Plugin::LighthouseReporter
#                                for a good example of how this method
#                                can be hooked to provide additional
#                                functionality.
#
# [Exceptionl::Plugin::Base#exception_links] Called when rendering
#                                            exception details. This
#                                            function should return an
#                                            array of [link_text,
#                                            link_href] pairs that
#                                            will be used to link to
#                                            additional routes that
#                                            the plugin might add.
#
# [Exceptionl::Plugin::Base#after_create] Called when a new exception
#                                         is
#                                         reported. Exceptionl::Plugin::EmailSender
#                                         has a good example of this
#                                         being used.
#
# After creating a plugin, it can be added to the server in the server
# configuration file or manually added using the
# Exceptionl::Server#plugins attribute.
module Exceptionl::Plugin
  autoload :Base, 'exceptionl/plugin/base'
  autoload :LighthouseReporter, 'exceptionl/plugin/lighthouse_reporter'
  autoload :EmailSender, 'exceptionl/plugin/email_sender'
end
