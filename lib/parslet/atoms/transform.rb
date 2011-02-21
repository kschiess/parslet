
require 'parslet/atoms/visitor'

# A helper class that allows transforming one grammar into another.
#
class Parslet::Atoms::Transform
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
  
  # TODO: at least roll context and block into one lambda.
  def visit_entity(name, context, block)
    transformer = self
    transformed_block = proc { context.instance_eval(&block).accept(transformer) }
    Parslet::Atoms::Entity.new(name, context, transformed_block)
  end
  
  def visit_named(name, parslet)
    parslet.accept(self).as(name)
  end
  
  def visit_repetition(min, max, parslet)
    parslet.accept(self).repeat(min, max)
  end
end