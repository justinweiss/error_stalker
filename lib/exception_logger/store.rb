module ExceptionLogger::Store
  autoload :Base, 'exception_logger/store/base'
  autoload :Mongoid, 'exception_logger/store/mongoid'
  autoload :InMemory, 'exception_logger/store/in_memory'
end
