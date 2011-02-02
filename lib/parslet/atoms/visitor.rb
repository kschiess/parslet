# Augments all parslet atoms with an accept method that will call back 
# to the visitor given.

# 
module Parslet::Atoms
  class Base
    def accept(visitor)
      raise NotImplementedError, "No visit method on #{self.class.name}."
    end
  end
  
  class Str
    # Call back visitors #str method. See parslet/export for an example. 
    #
    def accept(visitor)
      visitor.str(str)
    end
  end
  
  class Entity
    # Call back visitors #entity method. See parslet/export for an example. 
    #
    def accept(visitor)
      visitor.entity(name, context, block)
    end
  end
  
  class Named
    # Call back visitors #named method. See parslet/export for an example. 
    #
    def accept(visitor)
      visitor.named(name, parslet)
    end
  end
  
  class Sequence
    # Call back visitors #sequence method. See parslet/export for an example. 
    #
    def accept(visitor)
      visitor.sequence(parslets)
    end
  end
  
  class Repetition
    # Call back visitors #repetition method. See parslet/export for an example. 
    #
    def accept(visitor)
      visitor.repetition(min, max, parslet)
    end
  end
  
  class Alternative
    # Call back visitors #alternative method. See parslet/export for an example. 
    #
    def accept(visitor)
      visitor.alternative(alternatives)
    end
  end
  
  class Lookahead
    # Call back visitors #lookahead method. See parslet/export for an example. 
    #
    def accept(visitor)
      visitor.lookahead(positive, bound_parslet)
    end
  end
  
  class Re
    # Call back visitors #re method. See parslet/export for an example. 
    #
    def accept(visitor)
      visitor.re(match)
    end
  end
end
