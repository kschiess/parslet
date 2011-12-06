
require 'stringio'

require 'parslet/source/line_cache'

module Parslet
  # Wraps the input IO to parslet. The interface defined by this class is 
  # smaller than what IO offers, but enhances it with a #column and #line 
  # method for the current position. 
  #
  class Source
    def initialize(io)
      if io.respond_to? :to_str
        io = StringIO.new(io)
      end
    
      @io = io
      @line_cache = LineCache.new
    end
  
    # Reads n bytes from the input and returns a Range instance. If the n 
    # bytes end in the middle of a multibyte representation of a char, that 
    # char is returned fully. 
    #
    # Example: 
    #   source.read(1)  # always returns at least one valid char
    #   source.read(7)  # reads 7 bytes, then to the next char boundary.
    #
    def read(n)
      raise ArgumentError, "Cannot read < 1 characters at a time." if n < 1
      read_slice(n)
    end
  
    def eof?
      @io.eof?
    end
    def pos
      @io.pos
    end
    def pos=(new_pos)
      @io.pos = new_pos
    end

    # Returns a <line, column> tuple for the given position. If no position is
    # given, line/column information is returned for the current position given
    # by #pos. 
    #
    def line_and_column(position=nil)
      @line_cache.line_and_column(position || self.pos)
    end
  
    # Formats an error cause at the current position or at the position given 
    # by pos. If pos is nil, the current source position will be the error 
    # position.
    #
    def error(message, error_pos=nil)
      real_pos = (error_pos||self.pos)      
      
      Cause.format(self, real_pos, message)
    end
  
  private
    def read_slice(needed)
      start = @io.pos
      buf = @io.gets(nil, needed)

      # cache line ends
      @line_cache.scan_for_line_endings(start, buf)
    
      Parslet::Slice.new(buf || '', start, @line_cache)
    end
  
    if RUBY_VERSION !~ /^1.9/
      def read_slice(needed)
        start = @io.pos
        buf = @io.read(needed)

        # cache line ends
        @line_cache.scan_for_line_endings(start, buf)

        Parslet::Slice.new(buf || '', start, @line_cache)
      end
    end
  end
end