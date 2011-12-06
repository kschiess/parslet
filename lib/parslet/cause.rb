module Parslet
  # An internal class that allows delaying the construction of error messages
  # (as strings) until we really need to print them. 
  #
  class Cause < Struct.new(:message, :source, :pos) # :nodoc: 
    
    # Appends 'at line ... char ...' to the string given. Use +pos+ to
    # override the position of the +source+. This method returns an object
    # that can be turned into a string using #to_s.
    #
    def self.format(source, pos, str)
      self.new(str, source, pos)
    end
    
    def to_s
      line, column = source.line_and_column(pos)
      # Allow message to be a list of objects. Join them here, since we now
      # really need it. 
      Array(message).map { |o| 
        o.respond_to?(:to_slice) ? 
          o.str.inspect : 
          o.to_s }.join + " at line #{line} char #{column}."
    end
    
    # Signals to the outside that the parse has failed. Use this in
    # conjunction with .format for nice error messages. 
    #
    def raise(exception_klass=Parslet::ParseFailed)
      Kernel.raise exception_klass, self.to_s
    end
  end
end