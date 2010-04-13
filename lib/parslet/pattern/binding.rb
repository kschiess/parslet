
# Binds a symbol to a simple subtree, one that is not either a sequence of
# elements or a collection of attributes. 
#
class Parslet::Pattern::SimpleBind
  attr_reader :symbol
  def initialize(symbol)
    @symbol = symbol
  end
  
  def inspect
    "simple(#{symbol.inspect})"
  end
  
  def can_bind?(subtree)
    not [Hash, Array].include?(subtree.class)
  end
  
  def variable_name
    symbol
  end
end

# Binds a symbol to a sequence of simple subtrees ([tree1, tree2, ...])
#
class Parslet::Pattern::SequenceBind
  
end