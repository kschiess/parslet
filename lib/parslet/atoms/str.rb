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

    @str = str.to_s
    @error_msgs = {
      :premature  => "Premature end of input", 
      :failed     => "Expected #{str.inspect}, but got "
    }
  end
  
  def try(source, context) # :nodoc:
    # NOTE: Even though it doesn't look that way, this is the hotspot, the
    # contents of parslets inner loop. Changes here affect parslets speed 
    # enormously.
    error_pos = source.pos
    s = source.read(str.bytesize)

    return succ(s) if s == str
    
    # assert: s != str

    # Failures: 
    return context.err(self, source, @error_msgs[:premature]) \
      unless s && s.size==str.size
        
    return context.err_at(self, source, [@error_msgs[:failed], s], error_pos) 
  end
  
  def to_s_inner(prec) # :nodoc:
    "'#{str}'"
  end
end

