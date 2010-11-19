class Parslet::Expression::Treetop
  class Parser < Parslet::Parser
    root(:expression)
    
    rule(:expression) {
      (atom >> str('?')).as(:maybe) |
      atom
    }
    
    rule(:atom) { 
      str('(') >> expression >> str(')') |
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
  
  class Transform < Parser::Transform
    rule(:maybe => simple(:m)) { |d| d[:m].maybe }
    rule(:string => simple(:s)) { |d| str(d[:s]) }
  end
  
end

