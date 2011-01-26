# Augments all parslet atoms with an accept method that will call back 
# to the visitor given.

module Parslet::Atoms
  class Base
    def accept(visitor)
      raise NotImplementedError, "No visit method on #{self.class.name}."
    end
  end
  
  class Str
    def accept(visitor)
      visitor.str(str)
    end
  end
  
  class Entity
    def accept(visitor)
      visitor.entity(name, context, block)
    end
  end
  
  class Named
    def accept(visitor)
      visitor.named(name, parslet)
    end
  end
  
  class Sequence
    def accept(visitor)
      visitor.sequence(parslets)
    end
  end
  
  class Repetition
    def accept(visitor)
      visitor.repetition(min, max, parslet)
    end
  end
  
  class Alternative
    def accept(visitor)
      visitor.alternative(alternatives)
    end
  end
  
  class Lookahead
    def accept(visitor)
      visitor.lookahead(positive, bound_parslet)
    end
  end
  
  class Re
    def accept(visitor)
      visitor.re(match)
    end
  end
end
