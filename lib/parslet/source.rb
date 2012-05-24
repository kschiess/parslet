
require 'stringio'

require 'parslet/source/line_cache'

module Parslet
  # Wraps the input string for parslet. 
  #
  class Source
    def initialize(str)
      raise ArgumentError unless str.respond_to?(:to_str)
    
      @pos = 0
      @str = str
      
      @line_cache = LineCache.new
      @line_cache.scan_for_line_endings(0, @str)
    end
  
    # Checks if the given pattern matches at the current input position. 
    #
    # @param pattern [Regexp, String] pattern to check for
    # @return [Boolean] true if the pattern matches at #pos
    #
    def matches?(pattern)
      @str.index(pattern, @pos) == @pos
    end
    alias match matches?
    
    # Consumes n characters from the input, returning them as a slice of the
    # input. 
    #
    def consume(n)
      slice_str = @str.slice(@pos, n)
      slice = Parslet::Slice.new(
        slice_str, 
        pos,
        @line_cache)
      
      @pos += slice_str.size
      return slice
    end
    
    # Returns how many chars remain in the input. 
    #
    def chars_left
      @str.size - @pos
    end
    
    def eof?
      @pos >= @str.size
    end

    # Position of the parse as a character offset into the original string. 
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