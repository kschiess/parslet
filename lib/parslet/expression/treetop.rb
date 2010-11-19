class Parslet::Expression::Treetop
  class Parser < Parslet::Parser
    root(:expression)
    
    rule(:expression) {
      alternatives.as(:maybe) >> str('?') >> space? | 
      alternatives
    }
    
    rule(:alternatives) {
      simple >> str('/') >> alternatives |
      simple
    }

    rule(:simple) {
      atom.repeat
    }
    
    rule(:atom) { 
      str('(') >> expression.as(:unwrap) >> str(')') >> space? |
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
  end
  
  class Transform < Parser::Transform
    rule(:unwrap => simple(:u)) { u }
    rule(sequence(:s))          { |d| Parslet::Atoms::Sequence.new(*d[:s]) }
    rule(:maybe => simple(:m))  { |d| d[:m].maybe }
    rule(:string => simple(:s)) { |d| str(d[:s]) }
  end
  
end

