class Parslet::Expression::Treetop
  class Parser < Parslet::Parser
    root(:expression)
    
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
  
  class Transform < Parser::Transform
    rule(:string => simple(:s)) { |d| str(d[:s]) }
  end
  
end

