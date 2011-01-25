# Exception stores are places that the Exceptionl server will keep
# reported exceptions. Stores provide functionality like grouping
# exceptions, keeping track of exceptions, searching exceptions, and
# gathering recent exceptions. All Exceptionl stores should inherit
# from Exceptionl::Store::Base, and must implement all the methods
# defined on that class.
module Exceptionl::Store
  autoload :Base, 'exceptionl/store/base'
  autoload :Mongoid, 'exceptionl/store/mongoid'
  autoload :InMemory, 'exceptionl/store/in_memory'
end
