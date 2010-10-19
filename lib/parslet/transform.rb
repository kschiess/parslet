
require 'parslet/pattern'

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
# You will not be able to create a loop, given that each node will be replaced
# only once and then left alone. This means that the results of a replacement
# will not be acted upon. 
#
# Example: 
#
#   transform = Parslet::Transform.new
#   transform.rule(
#     :string => simple(:x)       # (1)
#   ) { |d| 
#     StringLiteral.new(d[:x])    # (2)
#   }
#
#   # Transforms the tree
#   transform.apply(tree) 
#
# A tree transform (Parslet::Transform) is defined by a set of rules. Each
# rule can be defined by calling #rule with the pattern as argument. The block
# given will be called every time the rule matches somewhere in the tree given
# to #apply. It is passed a Hash containing all the variable bindings of this
# pattern match. 
#  
# In the above example, (1) illustrates a simple matching rule. In general,
# such rules are composed of strings ("foobar"), arrays (["a", "b"]) and 
# hashes like in the example above. 
#
# Let's say you want to parse matching parentheses and distill a maximum 
# nest depth. You would probably write a parser like the one in example/parens.rb; 
# here's the relevant part: 
#
#   rule(:balanced) {
#     str('(').as(:l) >> balanced.maybe.as(:m) >> str(')').as(:r)
#   }
#
# If you now apply this to a string like '(())', you get a intermediate 
# parse tree that looks like this: 
#
#   {:l => "(", 
#     :m => [{:l=>"(", :m=>"", :r=>")"}], 
#     :r => ")"}
# XXX should not have an array!!
#
class Parslet::Transform
  def initialize
    @rules = []
  end
  
  attr_reader :rules
  def rule(expression, &block)
    @rules << [
      Parslet::Pattern.new(expression), 
      block
    ]
  end
  
  def apply(obj)
    case obj
      when Hash
        recurse_hash(obj)
      when Array
        recurse_array(obj)
    else
      transform_elt(obj)
    end
  end
  
  def transform_elt(elt)
    rules.each do |pattern, block|
      if bindings=pattern.match(elt)
        # Produces transformed value
        return block.call(bindings)
      end
    end
    
    # No rule matched - element is not transformed
    return elt
  end
  def recurse_hash(hsh)
    transform_elt(
      hsh.inject({}) do |new_hsh, (k,v)|
        new_hsh[k] = apply(v)
        new_hsh
      end)
  end
  def recurse_array(ary)
    transform_elt(
      ary.map { |elt| apply(elt) })
  end
end