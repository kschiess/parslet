
require 'stringio'

require 'parslet/source/line_cache'

# Wraps the input IO to parslet. The interface defined by this class is 
# smaller than what IO offers, but enhances it with a #column and #line 
# method for the current position. 
#
class Parslet::Source
  def initialize(io)
    if io.respond_to? :to_str
      io = StringIO.new(io)
    end
    
    @io = io
    @line_cache = LineCache.new
  end
  
  # Reads n chars from the input and returns a Range instance. 
  #
  def read(n)
    raise ArgumentError, "Cannot read <= 1 characters at a time." \
      if n < 1
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