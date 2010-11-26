class Parslet::Expression::Treetop
  class Parser < Parslet::Parser # :nodoc:
    root(:expression)
    
    rule(:expression) { alternatives }
    
    # alternative 'a' / 'b'
    rule(:alternatives) {
      (simple >> (spaced('/') >> simple).repeat).as(:alt)
    }
    
    # sequence by simple concatenation 'a' 'b'
    rule(:simple) { perhaps.repeat(1).as(:seq) }

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
  
  class Transform < Parser::Transform # :nodoc:
    rule(:alt => subtree(:alt)) { Parslet::Atoms::Alternative.new(*alt) }
    rule(:seq => sequence(:s))  { Parslet::Atoms::Sequence.new(*s) }
    rule(:unwrap => simple(:u)) { u }
    rule(:maybe => simple(:m))  { |d| d[:m].maybe }
    rule(:string => simple(:s)) { |d| str(d[:s]) }
  end
  
end

