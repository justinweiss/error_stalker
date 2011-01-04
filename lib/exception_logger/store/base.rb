module ExceptionLogger::Store

  # The base store that all other exception stores should inherit
  # from.
  class Base

    # Store this +exception_report+. 
    def store(exception_report)
      raise NotImplementedError, "Must be implemented by child class"
    end

    def all
      raise NotImplementedError, "Must be implemented by child class"
    end
  end
end
