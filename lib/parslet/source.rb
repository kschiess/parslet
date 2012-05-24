
require 'stringio'

require 'parslet/source/line_cache'

module Parslet
  # Wraps the input IO to parslet. The interface defined by this class is 
  # smaller than what IO offers, but enhances it with a #column and #line 
  # method for the current position. 
  #
  class Source
    def initialize(str)
      raise ArgumentError unless str.respond_to?(:to_str)
    
      @pos = 0
      @str = str
      @line_cache = LineCache.new
    end
  
    # Checks if the given pattern matches at the current input position. 
    #
    def matches?(pattern)
      @str.index(pattern, @pos) == @pos
    end
    
    # Consumes n characters from the input, returning them as a slice of the
    # input. 
    #
    def consume(n)
      slice_str = @str.slice(@pos, n)
      slice = Parslet::Slice.new(
        slice_str, 
        pos,
        @line_cache)
      
      @line_cache.scan_for_line_endings(@pos, slice_str)
      @pos += slice_str.bytesize
      return slice
    end
    
    # Returns how many bytes remain in the input. 
    #
    def remaining_bytes
      @str.bytesize - @pos
    end
    
    def eof?
      @pos >= @str.bytesize
    end

    # Position of the parse as a byte offset into the original string. 
    # @note: Encodings...
    attr_accessor :pos

    # Returns a <line, column> tuple for the given position. If no position is
    # given, line/column information is returned for the current position
    # given by #pos. 
    #
    def line_and_column(position=nil)
      @line_cache.line_and_column(position || self.pos)
    end
  end
end