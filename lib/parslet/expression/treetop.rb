class Parslet::Expression::Treetop
  class Parser < Parslet::Parser
    root(:expression)
    
    rule(:expression) {
      alternatives
    }
    
    rule(:alternatives) {
      simple >> (spaced('/') >> alternatives) |
      simple
    }
    
    rule(:simple) {
      perhaps.repeat
    }

    rule(:perhaps) {
      atom.as(:maybe) >> spaced('?') | 
      atom
    }
    
    rule(:atom) { 
      spaced('(') >> expression.as(:unwrap) >> spaced(')') |
      string 
    }

    rule(:string) {
      str('\'') >> 
      (
        (str('\\') >> any) |
        (str("'").absnt? >> any)
      ).repeat.as(:string) >> 
      str('\'') >> space?
    }
    
    rule(:space) { match("\s").repeat(1) }
    rule(:space?) { space.maybe }
    
    def spaced(str)
      str(str) >> space?
    end
  end
  
  class Transform < Parser::Transform
    rule(:unwrap => simple(:u)) { u }
    rule(sequence(:s))          { |d| Parslet::Atoms::Sequence.new(*d[:s]) }
    rule(:maybe => simple(:m))  { |d| d[:m].maybe }
    rule(:string => simple(:s)) { |d| str(d[:s]) }
  end
  
end

