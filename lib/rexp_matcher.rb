
class RExpMatcher
  attr_reader :obj
  def initialize(obj)
    @obj = obj
  end
  
  def match(expression, &block)
    bindings = {}
    if element_match(obj, expression, bindings)
      block.call(*bindings.values)
    end
  end
  
  def element_match(tree, exp, bindings) 
    p [:elm, tree, exp]
    case [tree, exp].map { |e| e.class }
      when [Hash,Hash]
        element_match_hash(tree, exp, bindings)
    else
      # If elements match exactly, then that is good enough in all cases
      return true if tree == exp
      
      # Otherwise: No match (we don't know anything about the element
      # combination)
      return false
    end
  end

  def element_match_hash(tree, exp, bindings)
    # For a hash to match, all keys must correspond and all values must 
    # match element wise.
    tree.each do |tree_key,tree_value|
      return nil unless exp.has_key?(tree_key)
      
      # We know they both have tk as element.
      exp_value = exp[tree_key]
      
      # Recurse into the values
      unless element_match(tree_value, exp_value, bindings)
        # Stop matching early
        return false
      end
    end
    
    # Match succeeds
    return true
  end
  
  # Returns true if the object is a symbol that starts with an underscore.
  # This is what we use as bind variable in pattern matches. 
  #
  def bind_variable?(obj)
    raise NotImplementedError
  end
  
  def inspect
    'r('+obj.inspect+')'
  end
end