
require 'parslet/atoms/visitor'

# A helper class that allows transforming one grammar into another. You can
# use this class as a base class: 
#
# Example: 
#   class MyTransform < Parslet::Atoms::Transform
#     def visit_str(str)
#       # mangle string here
#       super(str)
#     end
#   end
#
# Note that all the methods in a Transform must return parser atoms. The
# quickest way to do so is to call super with your own arguments. This will
# just create the same kind of atom that was just visited. 
#
# In essence, this base class performs what is called an 'identity transform'
# with one small caveat: It returns a brand new grammar composed of brand new
# parser atoms. This is like a deep clone of your grammar. 
#
# But nothing stops you from doing something that is far from a deep clone. 
# You can totally transform the language your grammar accepts. Or maybe
# turn all repetitions into non-greedy ones? Go wild. 
#
class Parslet::Atoms::Transform
  # Applies a transformation to a grammar and returns a new grammar that 
  # is the result of the transform.
  #
  # Example: 
  #   Parslet::Atoms::Transform.new.apply(my_grammar) # => deep clone of my_grammar
  #
  def apply(grammar)
    grammar.accept(self)
  end
  
  def visit_str(str)
    Parslet.str(str)
  end
  
  def visit_sequence(parslets)
    parslets[1..-1].inject(parslets[0]) { |a,p| a >> p.accept(self) }
  end
  
  def visit_re(match)
    Parslet.match(match)
  end
  
  def visit_alternative(parslets)
    parslets[1..-1].inject(parslets[0]) { |a,p| a | p.accept(self) }
  end
  
  def visit_lookahead(positive, parslet)
    Parslet::Atoms::Lookahead.new(positive, parslet.accept(self))
  end
  
  def visit_entity(name, block)
    # NOTE: This is kinda tricky. We return a new entity that keeps a reference
    # to the transformer around. Once somebody accesses the parslet in that
    # entity, the original block will produce the original parslet, and then
    # we transform that then and there. Its lazy and futuristic!
    transformer = self
    transformed_block = proc { block.call.accept(transformer) }
    Parslet::Atoms::Entity.new(name, &transformed_block)
  end
  
  def visit_named(name, parslet)
    parslet.accept(self).as(name)
  end
  
  def visit_repetition(min, max, parslet)
    parslet.accept(self).repeat(min, max)
  end
end