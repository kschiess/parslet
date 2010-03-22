
require 'rexp_matcher'

# Transforms an expression tree into something else. The transformation
# performs a depth-first, post-order traversal of the expression tree. During
# that traversal, each time a rule matches a node, the node is replaced by the
# result of the block associated to the rule. Otherwise the node is accepted
# as is into the result tree.
#
# This is almost what you would generally do with a tree visitor, except that
# you can match several levels of the tree at once. 
#
# As a consequence of this, the resulting tree will contain pieces of the
# original tree and new pieces. Most likely, you will want to transform the
# original tree wholly, so this isn't a problem.
#
# You will not be able to create a loop, given that 
#
# a) The matcher only matches simple nodes (leafs) to variables, not sequences 
#    or composites.
#
# b) Each node will be replaced only once and then left alone. This means that
#    the results of a replacement will not be acted upon. 
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