
# A slice is a small part from the parse input. A slice mainly behaves like
# any other string, except that it remembers where it came from (offset in 
# original input). 
#
# Some slices also know what parent slice they are a small part of. This 
# allows the slice to be concatenated to other slices from the same buffer
# by reslicing it against that original buffer. 
#
# Why the complexity? Slices allow retaining offset information. This will
# allow to assign line and column to each small bit of output from the 
# parslet parser. Also, while we keep that information, we might as well
# try to do something useful with it. Reslicing the same buffers should 
# in theory keep buffer copies and allocations down. 
#
class Parslet::Slice
  attr_reader :str, :offset
  attr_reader :parent
  
  def initialize(string, offset, parent=nil)
    @str, @offset = string, offset
    @parent = parent
  end
  
  # Compares slices to other slices or strings. 
  #
  def == other
    if other.instance_of?(Parslet::Slice)
      self.offset == other.offset && self.str == other.str
    else
      str == other
    end
  end
  
  # Match regular expressions. 
  # 
  def match(regexp)
    str.match(regexp)
  end
  
  # Reslicing
  #
  def slice(start, length)
    # NOTE: At a later stage, we might not want to create huge trees of slices. 
    # The fact that the root of the tree creates slices that link to it makes
    # the tree already rather flat. 
    
    if parent
      parent.slice(offset - parent.offset, length)
    else
      Parslet::Slice.new(str.slice(start, length), offset+start, self)
    end
  end
  def abs_slice(start, length)
    slice(start-offset, length)
  end
  
  # True if this slice can satisfy an original input request to the 
  # range ofs, len.
  #
  def satisfies?(ofs, len)
    ofs >= offset && (ofs-offset+len-1)<str.size
  end
  
  def size
    str.size
  end
  def +(other)
    raise Parslet::InvalidSliceOperation, "Cannot concat slices that aren't adjacent." \
      if offset+size != other.offset
       
    # If both slices stem from the same bigger buffer, we can reslice that 
    # buffer to obtain a lean result. 
    if parent && parent == other.parent
      return parent.abs_slice(offset, size+other.size)
    end
    
    self.class.new(str + other.str, offset)
  end
    
  def to_str
    str
  end
  alias to_s to_str
  
  def inspect
    "slice(#{str}, #{offset})"
  end
end

# Raised when trying to do an operation on slices that cannot succeed, like 
# adding non-adjacent slices. 
#
class Parslet::InvalidSliceOperation < StandardError
end