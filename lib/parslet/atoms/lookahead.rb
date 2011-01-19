# Either positive or negative lookahead, doesn't consume its input. 
#
# Example: 
#
#   str('foo').prsnt?   # matches when the input contains 'foo', but leaves it
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
      :positive => "lookahead: #{bound_parslet.inspect} didn't match, but should have", 
      :negative => "negative lookahead: #{bound_parslet.inspect} matched, but shouldn't have"
    }
  end
  
  def try(source, context) # :nodoc:
    pos = source.pos

    value = bound_parslet.apply(source, context)
    return success(nil) if positive ^ value.error?
    
    return error(source, @error_msgs[:positive]) if positive
    return error(source, @error_msgs[:negative])
    
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

  def error_tree # :nodoc:
    bound_parslet.error_tree
  end
end
