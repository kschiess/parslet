
# Wraps the input IO to parslet. The interface defined by this class is 
# smaller than what IO offers, but enhances it with a #column and #line 
# method for the current position. 
#
class Parslet::Source
  def initialize(io)
    @io = io
    warn "Line counting will be off if the IO is not rewound." unless @io.pos==0
    
    @line_ends = [io.pos]
  end
  
  def read(n)
    @io.read(n)
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
  
  def line
    1
  end
  
  def column
    1
  end
end