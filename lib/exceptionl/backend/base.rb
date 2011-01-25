module Exceptionl::Backend

  # The base class for exception logger backends. All backends should
  # inherit from this class and implement the +report+ method.
  class Base
    
    # Store an exception report into this backend. Subclasses should
    # override this method. +exception_report+ is an
    # Exceptionl::ExceptionReport instance.
    def report(exception_report)
      raise NotImplementedError, "This method must be overridden in subclasses"
    end
  end
end
