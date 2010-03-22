
require 'rexp_matcher'

# Transforms an expression tree into something else. 
#
class TreeTransform
  attr_reader :rules
  def rule(expression, &block)
    @rules ||= []
    @rules << [expression, block]
  end
  
  def apply(obj)
    case obj
      when Hash
        apply_hash(obj)
    else
      apply_elt(obj)
    end
  end
  
  def apply_elt(elt)
    rules.each do |rule, block|
      bindings = {}
      matcher = RExpMatcher.new(elt)
      if matcher.element_match(elt, rule, bindings)
        # Produces transformed value
        new_elt = block.call(bindings)
        
        # Applies rules to the new element as well. This might and WILL loop
        # if your rules specify that. (:_x => x for example)
        return apply(new_elt)
      end
    end
    
    # No rule matched - element is not transformed
    return elt
  end
  def apply_hash(hsh)
  end
end