# Either positive or negative lookahead, doesn't consume its input. 
#
# Example: 
#
#   str('foo').prsnt?   # matches when the input contains 'foo', but leaves it
#
class Parslet::Atoms::Lookahead < Parslet::Atoms::Base
  attr_reader :positive
  attr_reader :bound_parslet
  
  def initialize(bound_parslet, positive=true)
    # Model positive and negative lookahead by testing this flag.
    @positive = positive
    @bound_parslet = bound_parslet
  end
  
  def try(io)
    pos = io.pos
    begin
      bound_parslet.apply(io)
    rescue Parslet::ParseFailed 
      return fail(io)
    ensure 
      io.pos = pos
    end
    return success(io)
  end
  
  def fail(io)
    if positive
      error(io, "lookahead: #{bound_parslet.inspect} didn't match, but should have")
    else
      # TODO: Squash this down to nothing? Return value handling here...
      return nil
    end
  end
  def success(io)
    if positive
      return nil  # see above, TODO
    else
      error(
        io, 
        "negative lookahead: #{bound_parslet.inspect} matched, but shouldn't have")
    end
  end

  precedence LOOKAHEAD
  def to_s_inner(prec)
    char = positive ? '&' : '!'
    
    "#{char}#{bound_parslet.to_s(prec)}"
  end

  def error_tree
    bound_parslet.error_tree
  end
end
