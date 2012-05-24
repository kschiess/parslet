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
    return succ(source.consume(str.size)) if source.matches?(str)
    
    # Failures: 
    return context.err(self, source, @error_msgs[:premature]) \
      if source.remaining_bytes<str.bytesize
      
    error_pos = source.pos  
    return context.err_at(
      self, source, 
      [@error_msgs[:failed], source.consume(str.size)], error_pos) 
  end
  
  def to_s_inner(prec) # :nodoc:
    "'#{str}'"
  end
end

