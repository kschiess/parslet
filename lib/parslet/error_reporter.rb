module Parslet
  class ErrorReporter
    
    # Produces an instance of Fail and returns it. 
    #
    def err(source, message, children=nil)
      position = source.pos
      Cause.format(source, position, message, children)
    end

    # Produces an instance of Fail and returns it. 
    #
    def err_at(source, message, pos, children=nil)
      position = pos
      Cause.format(source, position, message, children)
    end

  end
end