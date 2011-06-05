
# A slice is a small part from the parse input. A slice mainly behaves like
# any other string, except that it remembers where it came from (offset in
# original input).
#
# Some slices also know what parent slice they are a small part of. This
# allows the slice to be concatenated to other slices from the same buffer by
# reslicing it against that original buffer.
#
# Why the complexity? Slices allow retaining offset information. This will
# allow to assign line and column to each small bit of output from the parslet
# parser. Also, while we keep that information, we might as well try to do
# something useful with it. Reslicing the same buffers should in theory keep
# buffer copies and allocations down.
#
# == Extracting line and column
#
# Using the #line_and_column method, you can extract the line and column in
# the original input where this slice starts.
#
# Example:
#   slice.line_and_column # => [1, 13]
#   slice.offset          # => 12
#
# == Likeness to strings
#
# Parslet::Slice behaves in many ways like a Ruby String. This likeness
# however is not complete - many of the myriad of operations String supports
# are not yet in Slice. You can always extract the internal string instance by
# calling #to_s.
#
# These omissions are somewhat intentional. Rather than maintaining a full
# delegation, we opt for a partial emulation that gets the job done.
#
# Note also that there are some things that work with strings that will never
# work when using slices. For instance, you cannot concatenate slices that
# aren't from the same source or that don't join up:
#
# Example:
#   big_slice = 'abcdef'
#   a = big_slice.slice(0, 2)   # => "ab"@0
#   b = big_slice.slice(4, 2)   # => "ef"@4
#
#   a + b # raises Parslet::InvalidSliceOperation
#
# This avoids creating slices with impossible offsets or that are
# discontinous.
#
class Parslet::Slice
  attr_reader :str, :offset
  attr_reader :source

  def initialize(string, offset, source=nil)
    @str, @offset = string, offset
    @source = source
  end

  # Compares slices to other slices or strings.
  #
  def == other
    str == other
  end

  # Match regular expressions.
  #
  def match(regexp)
    str.match(regexp)
  end

  # Returns the slices size in characters.
  #
  def size
    str.size
  end
  
  # Concatenate two slices; it is assumed that the second slice begins 
  # where the first one ends. The offset of the resulting slice is the same
  # as the one of this slice. 
  #
  def +(other)
    self.class.new(str + other.to_s, offset, source)
  end

  # Returns a <line, column> tuple referring to the original input.
  #
  def line_and_column
    raise ArgumentError, "No source was given, cannot infer line and column." \
      unless source

    source.line_and_column(self.offset)
  end


  # Conversion operators -----------------------------------------------------
  def to_str
    str
  end
  alias to_s to_str

  def to_slice
    self
  end
  def to_sym
    str.to_sym
  end
  def to_int
    Integer(str)
  end
  def to_i
    str.to_i
  end
  def to_f
    str.to_f
  end

  # Inspection & Debugging ---------------------------------------------------

  # Prints the slice as <code>"string"@offset</code>.
  def inspect
    str.inspect << "@#{offset}"
  end
end

# Raised when trying to do an operation on slices that cannot succeed, like
# adding non-adjacent slices. See Parslet::Slice.
#
class Parslet::InvalidSliceOperation < StandardError
end