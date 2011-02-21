
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
    parslets[1..-1].inject(parslets[0]) { |a,p| a >> p }
  end
end