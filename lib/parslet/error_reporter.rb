module Parslet
  class ErrorReporter
    
    # Produces an instance of Fail and returns it. 
    #
    def err(source, str, children=nil)
      cause = source.error(str)
      cause.children = children || []

      return cause
    end

    # Produces an instance of Fail and returns it. 
    #
    def err_at(source, str, pos, children=nil)
      cause = source.error(str, pos)
      cause.children = children || []
      
      return cause
    end

  end
end