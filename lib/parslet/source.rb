
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
    @virtual_position = @io.pos
    @eof_position = nil
    
    @line_cache = LineCache.new
    
    # Stores an array of <offset, buffer> tuples. 
    @buffers = []
  end
  
  # Reads n chars from the input and returns a Range instance. 
  #
  def read(n)
    range = read_range(@virtual_position, n)
    @virtual_position += range.size
    
    range
  end
  
  def eof?
    @eof_position && @virtual_position >= @eof_position
  end
  def pos
    @virtual_position
  end
  def pos=(new_pos)
    @virtual_position = new_pos
  end

  # Returns a <line, column> tuple for the given position. If no position is
  # given, line/column information is returned for the current position given
  # by #pos. 
  #
  def line_and_column(position=nil)
    @line_cache.line_and_column(position || self.pos)
  end
  
private
  # Minimal size of a single read
  MIN_READ_SIZE = 500
  # Number of buffers to keep 
  BUFFER_CACHE_SIZE = 3
  
  # Reads and returns a piece of the input that contains length chars starting
  # at offset. 
  #
  def read_range(offset, length)
    # Do we already have a buffer that contains the given range?
    # Return that. 
    buffer = @buffers.find { |buffer| 
      buffer.satisfies?(offset, length) }
    return buffer.range(offset, length) if buffer
    
    # Read a new buffer: Can the demand be satisfied by sequentially reading
    # from the current position?
    needed = offset-@io.pos+length
    if @io.pos <= offset && needed<MIN_READ_SIZE
      # read the buffer
      buffer = physical_read(needed)
    
      # return the range
      return buffer.range(offset, length)
    end
    
    # Otherwise seek and read enough so that we can satisfy the demand. 
    @io.pos = offset
    buffer = physical_read(length)
    return buffer.range(offset, length)
  end
    
  def physical_read(needed)
    start = @io.pos
    request = [MIN_READ_SIZE, needed].max
    buf = @io.read(request)
    
    # remember eof position
    if !buf || buf.size<request
      @eof_position = @io.pos
    end
    
    buffer = Buffer.new(start, buf)
    
    # cache line ends
    @line_cache.scan_for_line_endings(start, buf)
    
    # cache the buffer
    @buffers << buffer
    @buffer.shift if @buffers.size > BUFFER_CACHE_SIZE
    
    buffer
  end
end