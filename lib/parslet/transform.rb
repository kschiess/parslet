
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
#   class Example < Parslet::Transform
#     rule(:string => simple(:x)) {  # (1)
#       StringLiteral.new(x)
#     }
#   end
#
# A tree transform (Parslet::Transform) is defined by a set of rules. Each
# rule can be defined by calling #rule with the pattern as argument. The block
# given will be called every time the rule matches somewhere in the tree given
# to #apply. It is passed a Hash containing all the variable bindings of this
# pattern match. 
#   
# In the above example, (1) illustrates a simple matching rule. 
#
# Let's say you want to parse matching parentheses and distill a maximum nest
# depth. You would probably write a parser like the one in example/parens.rb;
# here's the relevant part: 
#
#   rule(:balanced) {
#     str('(').as(:l) >> balanced.maybe.as(:m) >> str(')').as(:r)
#   }
#
# If you now apply this to a string like '(())', you get a intermediate parse
# tree that looks like this: 
#
#   {
#     :l => "(", 
#     :m => {
#       :l=>"(", :m=>nil, :r=>")" }, 
#     :r => ")"
#   }
#
# This parse tree is good for debugging, but what we would really like to have
# is just the nesting depth. This transformation rule will produce that: 
#
#   rule(:l => '(', :m => simple(:x), :r => ')') { 
#     # innermost :m will contain nil
#     x.nil? ? 1 : x+1
#   }
#
# = Usage patterns
#
# There are four ways of using this class. The first one is very much
# recommended, followed by the second one for generality. The other ones are
# omitted here. 
#
# Recommended usage is as follows: 
#
#   class MyTransformator < Parslet::Transform
#     rule(...) { ... }
#     rule(...) { ... }
#     # ...
#   end
#   MyTransformator.new.apply(tree)
#
# Alternatively, you can use the Transform class as follows: 
#
#   transform = Parslet::Transform.new do
#     rule(...) { ... }
#   end
#   transform.apply(tree)
#
class Parslet::Transform
  # FIXME: Maybe only part of it? Or maybe only include into constructor
  # context?
  include Parslet   

  class << self
    # FIXME: Only do this for subclasses?
    include Parslet
    
    # Define a rule for the transform subclass. 
    #
    def rule(expression, &block)
      @__transform_rules ||= []
      @__transform_rules << [Parslet::Pattern.new(expression), block]
    end
    
    # Allows accessing the class' rules
    #
    def rules
      @__transform_rules || []
    end
  end
  
  def initialize(&block)
    @rules = []
    
    if block
      instance_eval(&block)
    end
  end
  
  def rule(expression, &block)
    @rules << [
      Parslet::Pattern.new(expression), 
      block
    ]
  end
  
  def apply(obj)
    transform_elt(
      case obj
        when Hash
          recurse_hash(obj)
        when Array
          recurse_array(obj)
      else
        obj
      end
    )
  end
  
  # Allow easy access to all rules, the ones defined in the instance and the 
  # ones predefined in a subclass definition. 
  #
  def rules
    self.class.rules + @rules
  end
  
  def transform_elt(elt)
    rules.each do |pattern, block|
      if bindings=pattern.match(elt)
        # Produces transformed value
        return pattern.call_on_match(elt, bindings, block)
      end
    end
    
    # No rule matched - element is not transformed
    return elt
  end
  def recurse_hash(hsh)
    hsh.inject({}) do |new_hsh, (k,v)|
      new_hsh[k] = apply(v)
      new_hsh
    end
  end
  def recurse_array(ary)
    ary.map { |elt| apply(elt) }
  end
end