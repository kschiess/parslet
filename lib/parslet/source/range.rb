
class Parslet::Source
  class Range
    def initialize(offset, length, buffer)
      @offset, @length = offset, length
      @slice_offset = @offset - buffer.start
      @buffer = buffer
    end
    
    def size
      rem = max(@buffer.size-@slice_offset, 0)
      min(@length, rem)
    end
    
    def to_s
      @buffer.buffer.slice(@slice_offset,@length)
    end
    
    def inspect
      "range(#{to_s.inspect})"
    end
    
    def ==(other)
      to_s == other
    end
    
    def match(regexp)
      to_s.match(regexp)
    end
    
  private
    def min(a, b)
      a > b ? b : a
    end
    def max(a, b)
      a > b ? a : b
    end
  end
end