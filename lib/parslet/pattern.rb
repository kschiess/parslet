
# Matches trees against expressions. Trees are formed by arrays and hashes
# for expressing membership and sequence. The leafs of the tree are other
# classes. 
#
# A tree issued by the parslet library might look like this: 
#
#   { 
#     :function_call => {
#       :name => 'foobar', 
#       :args => [1, 2, 3]
#     }
#   }
#
class Parslet::Pattern
  def initialize(pattern)
    @pattern = pattern
  end

  # Searches the given +tree+ for this pattern, yielding the subtrees that
  # match to the block. 
  #
  # Example: 
  #
  #   tree = parslet.apply(input)
  #   pat = Parslet::Pattern.new(:_x)
  #   pat.each_match(tree) do |subtree|
  #     # do something with the matching subtree here
  #   end
  #
  def each_match(tree, &block) # :yield: subtree
    recurse_into(tree) do |subtree|
      if bindings=match(subtree)
        block.call(bindings) if block
      end
    end
    
    return nil
  end
  
  # Decides if the given subtree matches this pattern. Returns the bindings
  # made on a successful match or nil if the match fails. 
  #
  def match(subtree)
    bindings = {}
    return bindings if element_match(subtree, @pattern, bindings)
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
    
  # Returns true if the tree element given by +tree+ matches the expression
  # given by +exp+. This match must respect bindings already made in
  # +bindings+. 
  #
  def element_match(tree, exp, bindings) 
    # p [:elm, tree, exp]
    case [tree, exp].map { |e| e.class }
      when [Hash,Hash]
        return element_match_hash(tree, exp, bindings)
      when [Array,Array]
        return element_match_ary_single(tree, exp, bindings)
    else
      # If elements match exactly, then that is good enough in all cases
      return true if tree == exp
      
      # If exp is a bind variable: Check if the binding matches
      if exp.respond_to?(:can_bind?) && exp.can_bind?(tree)
        return element_match_binding(tree, exp, bindings)
      end
                  
      # Otherwise: No match (we don't know anything about the element
      # combination)
      return false
    end
  end
  
  def element_match_binding(tree, exp, bindings)
    var_name = exp.variable_name

    # TODO test for the hidden :_ feature.
    if var_name && bound_value = bindings[var_name]
      return bound_value == tree
    end
    
    # New binding: 
    bindings.store var_name, tree
    
    return true
  end
  
  def element_match_ary_single(sequence, exp, bindings)
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
      
  # Called on a bind variable, returns the variable name without the _
  #
  def variable_name(bind_var)
    str = bind_var.to_s
    
    if str.size>1
      str[1..-1].to_sym
    end
  end
end