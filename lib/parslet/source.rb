
require 'stringio'
require 'strscan'
require 'forwardable'

require 'parslet/source/line_cache'

module Parslet
  # Wraps the input string for parslet. 
  #
  class Source
    extend Forwardable

    def initialize(str)
      raise ArgumentError unless str.respond_to?(:to_str)

      @str = StringScanner.new(str)

      @line_cache = LineCache.new
      @line_cache.scan_for_line_endings(0, str)
    end
  
    # Checks if the given pattern matches at the current input position. 
    #
    # @param pattern [Regexp, String] pattern to check for
    # @return [Boolean] true if the pattern matches at #pos
    #
    def matches?(pattern)
      regexp = pattern.is_a?(String) ? Regexp.new(Regexp.escape(pattern)) : pattern
      !@str.match?(regexp).nil?
    end
    alias match matches?
    
    # Consumes n characters from the input, returning them as a slice of the
    # input. 
    #
    def consume(n)
      original_pos = @str.pos
      slice_str = n.times.map { @str.getch }.join
      slice = Parslet::Slice.new(
        slice_str,
        original_pos,
        @line_cache)

      return slice
    end
    
    # Returns how many chars remain in the input. 
    #
    def chars_left
      @str.rest_size
    end
    
    # Position of the parse as a character offset into the original string. 
    # @note: Encodings...
    def_delegator :@str, :pos
    def pos=(n)
      if n > @str.string.bytesize
        @str.pos = @str.string.bytesize
      else
        @str.pos = n
      end
    end

    # Returns a <line, column> tuple for the given position. If no position is
    # given, line/column information is returned for the current position
    # given by #pos. 
    #
    def line_and_column(position=nil)
      @line_cache.line_and_column(position || self.pos)
    end
  end
end
