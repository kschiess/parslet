# Matches a string of characters. 
#
# Example: 
# 
#   str('foo') # matches 'foo'
#
class Parslet::Atoms::Str < Parslet::Atoms::Base
  attr_reader :str
  def initialize(str)
    @str = str
  end
  
  def try(io)
    old_pos = io.pos
    s = io.read(str.size)
    error(io, "Premature end of input") unless s && s.size==str.size
    error(io, "Expected #{str.inspect}, but got #{s.inspect}", old_pos) \
      unless s==str
    return s
  end
  
  def to_s_inner(prec)
    "'#{str}'"
  end
end

