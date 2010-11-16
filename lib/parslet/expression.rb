
# Allows specifying rules as strings using the exact same grammar that treetop
# does, minus the actions. This is on one hand a good example of a fully fledged
# parser and on the other hand might even turn out really useful. 
# 
# NOT FINISHED & EXPERIMENTAL
#
class Parslet::Expression
  include Parslet
  
  def initialize(str)
    @exp = str
    @parslet = transform(
      parse(str))
  end
  
  # Transforms the parse tree into a parslet expression. 
  #
  def transform(tree)
    transform = Parslet::Transform.new
    transform.rule(:string => simple(:str)) { |d| 
      str(d[:str]) }
    
    transform.apply(tree)
  end
  
  class Treetop
    include Parslet
    
    # root :expression
    def parse(str)
      expression.parse(str)
    end
    
    rule(:expression) {
      string
    }
    
    rule(:string) {
      str('\'') >> 
      (
        (str('\\') >> any) |
        (str("'").absnt? >> any)
      ).repeat.as(:string) >> 
      str('\'')
    }
  end
  
  # Parses the string and returns a parse tree.
  #
  def parse(str)
    parser = Treetop.new
    parser.parse(str)
  end

  # Turns this expression into a parslet.
  #
  def to_parslet
    @parslet
  end
end