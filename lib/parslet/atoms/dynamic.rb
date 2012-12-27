# Evaluates a block at parse time. The result from the block can be either
# a parser or a result from calling a parser. In the first case, the parser
# will then be applied to the input, creating the result. 
#
# Dynamic parses are never cached. 
#
# Example: 
#   dynamic { rand < 0.5 ? str('a') : str('b') }
#
class Parslet::Atoms::Dynamic < Parslet::Atoms::Base
  attr_reader :block
  
  def initialize(block)
    @block = block
  end
  
  def cached?
    false
  end
  
  def try(source, context, consume_all)
    result = block.call(source, context)
    
    # Result is either a parslet atom, in which case we apply it to the input,
    # or it is a result from a parslet atom, in which case we return it
    # directly. 
    if result.respond_to?(:apply)
      return result.apply(source, context, consume_all)
    else
      return result
    end
  end
end

