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
    # Model positive and negative lookahead by testing this flag.
    @positive = positive
    @bound_parslet = bound_parslet
  end
  
  def try(io) # :nodoc:
    pos = io.pos

    failed = true
    catch(:error) {
      bound_parslet.apply(io)
      failed = false
    }
    return failed ? fail(io) : success(io)

  ensure 
    io.pos = pos
  end
  
  # TODO Both of these will produce results that could be reduced easily. 
  # Maybe do some shortcut reducing here?
  def fail(io) # :nodoc:
    if positive
      error(io, "lookahead: #{bound_parslet.inspect} didn't match, but should have")
    else
      return nil
    end
  end
  def success(io) # :nodoc:
    if positive
      return nil
    else
      error(
        io, 
        "negative lookahead: #{bound_parslet.inspect} matched, but shouldn't have")
    end
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
