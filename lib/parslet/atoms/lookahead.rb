# Either positive or negative lookahead, doesn't consume its input. 
#
# Example: 
#
#   str('foo').present? # matches when the input contains 'foo', but leaves it
#
class Parslet::Atoms::Lookahead < Parslet::Atoms::Base
  attr_reader :positive
  attr_reader :bound_parslet
  
  def initialize(bound_parslet, positive=true) # :nodoc:
    super()
    
    # Model positive and negative lookahead by testing this flag.
    @positive = positive
    @bound_parslet = bound_parslet
    
    @error_msgs = {
      :positive => ["Input should start with ", bound_parslet], 
      :negative => ["Input should not start with ", bound_parslet]
    }
  end
  
  def try(source, context) # :nodoc:
    pos = source.pos

    value = bound_parslet.apply(source, context)
    return success(nil) if positive ^ value.error?
    
    return error_at(source, @error_msgs[:positive], pos) if positive
    return error_at(source, @error_msgs[:negative], pos)
    
  # This is probably the only parslet that rewinds its input in #try.
  # Lookaheads NEVER consume their input, even on success, that's why. 
  ensure 
    source.pos = pos
  end
  
  precedence LOOKAHEAD
  def to_s_inner(prec) # :nodoc:
    char = positive ? '&' : '!'
    
    "#{char}#{bound_parslet.to_s(prec)}"
  end
end
