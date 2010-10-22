
# Used internally for representing a bind placeholder in a Parslet::Transform
# pattern. This is the superclass for all bindings. 
#
class Parslet::Pattern::Bind
  attr_reader :symbol
  def initialize(symbol)
    @symbol = symbol
  end

  def variable_name
    symbol
  end
end

# Binds a symbol to a simple subtree, one that is not either a sequence of
# elements or a collection of attributes. 
#
class Parslet::Pattern::SimpleBind < Parslet::Pattern::Bind
  def inspect
    "simple(#{symbol.inspect})"
  end
  
  def can_bind?(subtree)
    not [Hash, Array].include?(subtree.class)
  end
end

# Binds a symbol to a sequence of simple leafs ([element1, element2, ...])
#
class Parslet::Pattern::SequenceBind < Parslet::Pattern::Bind
  def inspect
    "sequence(#{symbol.inspect})"
  end
  
  def can_bind?(subtree)
    subtree.kind_of?(Array) &&
      (not subtree.any? { |el| [Hash, Array].include?(el.class) })
  end
end