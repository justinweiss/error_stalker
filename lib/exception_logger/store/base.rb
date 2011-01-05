module ExceptionLogger::Store

  # The base store that all other exception stores should inherit
  # from.
  class Base

    # Store this +exception_report+. 
    def store(exception_report)
      raise NotImplementedError, "Must be implemented by child class"
    end

    # Return the most recent exception groups. Should return an array
    # of <tt>[[count, most_recent_exception_report], ...]</tt>
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

    # returns the group this exception is a part of, ordered by
    # timestamp
    def group(digest)
      raise NotImplementedError, "Must be implemented by child class"
    end
  end
end
