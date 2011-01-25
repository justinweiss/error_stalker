# Exceptionl backends are objects representing a place that
# Exceptionl::Client sends exceptions to. A backend simply needs to
# inherit from Exceptionl::Backend::Base and override the +report+
# method, after which they can be set using the
# Exceptionl::Client.backend attribute. 
#
# The default backend is an Exceptionl::Backend::LogFile instance,
# which logs exception data to a file.
module Exceptionl::Backend
  autoload :Base, 'exceptionl/backend/base'
  autoload :InMemory, 'exceptionl/backend/in_memory'
  autoload :LogFile, 'exceptionl/backend/log_file'
  autoload :Server, 'exceptionl/backend/server'
end
