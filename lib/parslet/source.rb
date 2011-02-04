
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
    @line_ends.extend RangeSearch
  end
  
  def read(n)
    start_pos = pos
    @io.read(n).tap { |buf| scan_for_line_endings(start_pos, buf) }
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
    pos = (position || self.pos)
    eol_idx = @line_ends.lbound(pos)
    
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

  # Mixin for arrays that implicitly give a number of ranges, where one range
  # begins where the other one ends.
  # 
  #   Example: 
  #
  #     [10, 20, 30]
  #     # would describe [0, 10], (10, 20], (20, 30]
  #
  module RangeSearch
    # Scans the array for the first number that is > than bound. Returns the 
    # index of that number. 
    #
    def lbound(bound)
      return nil if empty?
      return nil unless last > bound

      left = 0
      right = size - 1 
    
      n = 10
      loop do
        mid = left + (right - left) / 2
        
        if self[mid] > bound
          right = mid
        else
          # assert: self[mid] <= bound
          left = mid+1
        end
        
        if right <= left
          return right
        end
      end
    end
  end
  
private

  def scan_for_line_endings(start_pos, buf)
    return unless buf
    return unless buf.index("\n")
    cur = -1
    
    # If we have already read part or all of buf, we already know about
    # line ends in that portion. remove it and correct cur (search index)
    if @last_line_end && start_pos < @last_line_end
      # Let's not search the range from start_pos to last_line_end again.
      cur = @last_line_end - start_pos -1
    end
    
    # Scan the string for line endings; store the positions of all endings
    # in @line_ends. 
    while buf && cur = buf.index("\n", cur+1)
      @last_line_end = (start_pos + cur+1)
      @line_ends << @last_line_end
    end 
  end
end