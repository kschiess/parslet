# Matches a string of characters. 
#
# Example: 
# 
#   str('foo') # matches 'foo'
#
class Parslet::Atoms::Str < Parslet::Atoms::Base
  attr_reader :str
  def initialize(str)
    super()

    @str = str
    @error_msgs = {
      :premature  => "Premature end of input", 
      :failed     => "Expected #{str.inspect}, but got "
    }
  end
  
  def try(source, context) # :nodoc:
    error_pos = source.pos
    s = source.read(str.size)

    error(source, @error_msgs[:premature]) unless s && s.size==str.size
    error(source, @error_msgs[:failed]+s.inspect, error_pos) \
      unless s==str
        
    return s
  end
  
  def to_s_inner(prec) # :nodoc:
    "'#{str}'"
  end
end

