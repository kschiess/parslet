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
    @error_msgs = {
      :premature  => "Premature end of input", 
      :failed     => "Expected #{str.inspect}, but got "
    }
  end
  
  def try(io) # :nodoc:
    old_pos = io.pos
    s = io.read(str.size)
    error(io, @error_msgs[:premature]) unless s && s.size==str.size
    error(io, @error_msgs[:failed]+s.inspect, old_pos) \
      unless s==str
    return s
  end
  
  def to_s_inner(prec) # :nodoc:
    "'#{str}'"
  end
end

