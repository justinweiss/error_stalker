# Simple plugin architecture for the exceptionl server.
module Exceptionl::Plugin
  autoload :Base, 'exceptionl/plugin/base'
  autoload :LighthouseReporter, 'exceptionl/plugin/lighthouse_reporter'
  autoload :EmailSender, 'exceptionl/plugin/email_sender'
end
