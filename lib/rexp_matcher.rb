
class RExpMatcher
  attr_reader :obj
  def initialize(obj)
    @obj = obj
  end
  
  def recurse_into(expr, &block)
    # p [:attempt_match, expr]
    block.call(expr)
    
    case expr
      when Array
        expr.each { |y| recurse_into(y, &block) }
      when Hash
        expr.each { |k,v| recurse_into(v, &block) }
    end
  end
  
  def match(expression, &block)
    recurse_into(obj) do |subtree|
      bindings = {}
      if element_match(subtree, expression, bindings)
        block.call(bindings)
      end
    end
    
    return self # allow chaining
  end
  
  def element_match(tree, exp, bindings) 
    # p [:elm, tree, exp]
    case [tree, exp].map { |e| e.class }
      when [Hash,Hash]
        element_match_hash(tree, exp, bindings)
      when [Array,Array]
        element_match_ary(tree, exp, bindings)
    else
      # If elements match exactly, then that is good enough in all cases
      return true if tree == exp
      
      # If exp is a bind variable: Check if the binding matches
      if bind_variable?(exp) && ! [Hash, Array].include?(tree.class)
        return element_match_binding(tree, exp, bindings)
      end
                  
      # Otherwise: No match (we don't know anything about the element
      # combination)
      return false
    end
  end
  
  def element_match_binding(tree, exp, bindings)
    var_name = variable_name(exp)
    # TODO test for the hidden :_ feature.
    if var_name && bound_value = bindings[var_name]
      return bound_value == tree
    end
    
    # New binding: 
    bindings.store var_name, tree
    
    return true
  end
  
  def element_match_ary(sequence, exp, bindings)
    return false if sequence.size != exp.size
    
    return sequence.zip(exp).all? { |elt, subexp|
      element_match(elt, subexp, bindings) }
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
    obj.instance_of?(Symbol) && obj.to_s.start_with?('_')
  end
  
  # Called on a bind variable, returns the variable name without the _
  #
  def variable_name(bind_var)
    str = bind_var.to_s
    
    if str.size>1
      str[1..-1].to_sym
    end
  end
  
  def inspect
    'r('+obj.inspect+')'
  end
end