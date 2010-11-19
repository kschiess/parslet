
# Allows specifying rules as strings using the exact same grammar that treetop
# does, minus the actions. This is on one hand a good example of a fully fledged
# parser and on the other hand might even turn out really useful. 
# 
# NOT FINISHED & EXPERIMENTAL
#
class Parslet::Expression
  include Parslet
  
  autoload :Treetop, 'parslet/expression/treetop'
  
  def initialize(str, opts={})
    @type = opts[:type] || :treetop
    @exp = str
    @parslet = transform(
      parse(str))
  end
  
  # Transforms the parse tree into a parslet expression. 
  #
  def transform(tree)
    transform = Treetop::Transform.new
    
    transform.apply(tree)
  end
  
  # Parses the string and returns a parse tree.
  #
  def parse(str)
    parser = Treetop::Parser.new
    parser.parse(str)
  end

  # Turns this expression into a parslet.
  #
  def to_parslet
    @parslet
  end
end