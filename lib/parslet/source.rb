
require 'stringio'

# Wraps the input IO to parslet. The interface defined by this class is 
# smaller than what IO offers, but enhances it with a #column and #line 
# method for the current position. 
#
class Parslet::Source
  attr_reader :line_ends
  
  def initialize(io)
    if io.respond_to? :to_str
      io = StringIO.new(io)
    end
    
    @io = io
    warn "Line counting will be off if the IO is not rewound." unless @io.pos==0
    
    # Stores line endings as a simple position number. The first line always
    # starts at 0; numbers beyond the biggest entry are on any line > size, 
    # but probably make a scan to that position neccessary.
    @line_ends = []
  end
  
  def read(n)
    start_pos = pos
    @io.read(n).tap { |buf| 
      cur = -1
      while buf && cur = buf.index("\n", cur+1)
        @line_ends << (start_pos + cur+1)
      end }
  end
  
  def eof?
    @io.eof?
  end
  
  def pos
    @io.pos
  end
  
  def pos=(new_pos)
    # Are we seeking beyond the last line?
    last_offset = line_ends.last
    if last_offset && new_pos > last_offset
      raise NotImplementedError
    end
    @io.pos = new_pos
  end
  
  def line_and_column(position=nil)
    pos = (position || self.pos)
    eol_idx = @line_ends.index { |o| o>pos }
    
    if eol_idx
      # eol_idx points to the offset that ends the current line.
      # Let's try to find the offset that starts it: 
      offset = eol_idx>0 && @line_ends[eol_idx-1] || 0
      return [eol_idx+1, pos-offset+1]
    else
      # eol_idx is nil, that means that we're beyond the last line end that
      # we know about. Pretend for now that we're just on the last line.
      offset = @line_ends.last || 0
      return [@line_ends.size+1, pos-offset+1]
    end
  end
end