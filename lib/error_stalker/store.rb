# Exception stores are places that the ErrorStalker server will keep
# reported exceptions. Stores provide functionality like grouping
# exceptions, keeping track of exceptions, searching exceptions, and
# gathering recent exceptions. All ErrorStalker stores should inherit
# from ErrorStalker::Store::Base, and must implement all the methods
# defined on that class.
module ErrorStalker::Store
  autoload :Base, 'error_stalker/store/base'
  autoload :Mongoid, 'error_stalker/store/mongoid'
  autoload :InMemory, 'error_stalker/store/in_memory'
end
