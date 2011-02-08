
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
    warn "Line counting will be off if the IO is not rewound." unless @io.pos==0
    
    @line_cache = LineCache.new
  end
  
  def read(n)
    start_pos = pos
    @io.read(n).tap { |buf| @line_cache.scan_for_line_endings(start_pos, buf) }
  end
  
  def eof?
    @io.eof?
  end
  
  def pos
    @io.pos
  end

  # NOTE: If you seek beyond the point that you last read, you will get 
  # undefined behaviour. This is by design. 
  def pos=(new_pos)
    @io.pos = new_pos
  end
    
  def line_and_column(position=nil)
    @line_cache.line_and_column(position || self.pos)
  end
end