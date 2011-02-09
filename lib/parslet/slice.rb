
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
  attr_reader :str, :ofs
  
  def initialize(string, offset, parent=nil)
    @str, @ofs = string, offset
    @parent = parent
  end
  
  # Compares slices to other slices or strings. 
  #
  def == other
    if other.instance_of?(Parslet::Slice)
      self.ofs == other.ofs && self.str == other.str
    else
      str == other
    end
  end
  
  def to_str
    fail 'to_str?'
  end
  
  def inspect
    "slice(#{str}, #{ofs})"
  end
end