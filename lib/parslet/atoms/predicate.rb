
# Allows execution of code in line with parsing. The code can use the result
# of a subexpression to decide if a parse should go ahead or fail at this
# point.
#
# Please note that the block will probably be memoized and not executed 
# more than once for any input position. Predicates are NOT grammar actions, 
# and I you use them as such, you're on your own. 
#
# Example: 
#   (str('bacon') | str('chunky')).pred { |m| m != 'chunky' }
#   # for when you don't really want chunky bacon.
#
class Parslet::Atoms::Predicate < Parslet::Atoms::Base
  attr_reader :parslet, :predicate
  
  def initialize(parslet, &predicate)
    @predicate = predicate
    @parslet = parslet
  end
  
  def try(source, context)
    error_pos = source.pos

    value = parslet.apply(source, context)
    return value if value.error?
    
    flat_result = flatten(value.result)
    if predicate.call(flat_result)
      # TODO once we have intermediary flattening, make this return the 
      # flat result.
      return success(value)
    else
      return error(source, "Predicate failure", error_pos)
    end
    
    fail 'BUG'
  end
  
  def to_s_inner(prec) # :nodoc:
    parslet.to_s(prec) + " &{ .. }"
  end
  
  def error_tree # :nodoc:
    parslet.error_tree
  end
end