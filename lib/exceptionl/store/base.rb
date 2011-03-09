require 'exceptionl/exception_group'

module Exceptionl::Store
  # The base store that all other exception stores should inherit
  # from. All methods on this class must be inherited by subclasses,
  # and the methods that return multiple objects must support
  # pagination. 
  class Base

    # Store this +exception_report+, however the store wishes to.
    def store(exception_report)
      raise NotImplementedError, "Must be implemented by child class"
    end

    # Return the most recent exception groups. Should return an array
    # of Exceptionl::ExceptionGroup objects.
    def recent
      raise NotImplementedError, "Must be implemented by child class"
    end

    # Have any exceptions been logged? If not, return +true+
    def empty?
      raise NotImplementedError, "Must be implemented by child class"
    end
    
    # Find an exception report with the given id
    def find(id)
      raise NotImplementedError, "Must be implemented by child class"
    end

    # Returns the ExceptionGroup matching +digest+
    def group(digest)
      raise NotImplementedError, "Must be implemented by child class"
    end
    
    # Returns a list of exceptions whose digest is +digest+.
    def reports_in_group(digest)
      raise NotImplementedError, "Must be implemented by child class"
    end

    # A list of all the applications that have seen exceptions
    def applications
      raise NotImplementedError, "Must be implemented by child class"
    end

    # A list of all the machines that have seen exceptions
    def machines
      raise NotImplementedError, "Must be implemented by child class"
    end

    # Does this store support searching through the data blob?
    def supports_extended_searches?
      false
    end
    
    # Searches for exception reports maching +params+. Search should
    # support searching by application name, machine name, exception
    # name, and exception type. The keys in +params+ should match
    # attributes of Exceptionl::ExceptionReport, and the results
    # should be ordered by timestamp from newest to oldest.
    def search(params)
      raise NotImplementedError, "Must be implemented by child class"
    end
  end
end
