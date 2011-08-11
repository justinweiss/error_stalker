# ErrorStalker backends are objects representing a place that
# ErrorStalker::Client sends exceptions to. A backend simply needs to
# inherit from ErrorStalker::Backend::Base and override the +report+
# method, after which they can be set using the
# ErrorStalker::Client.backend attribute. 
#
# The default backend is an ErrorStalker::Backend::LogFile instance,
# which logs exception data to a file.
module ErrorStalker::Backend
  autoload :Base, 'error_stalker/backend/base'
  autoload :InMemory, 'error_stalker/backend/in_memory'
  autoload :LogFile, 'error_stalker/backend/log_file'
  autoload :Server, 'error_stalker/backend/server'
end
