# Allows exporting parslet grammars to other lingos. 


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

class Parslet::Parser
  
  class GrammarPrintVisitor
    attr_reader :output
    def initialize
      @output = ''
    end
    
    def str(str)
      output << "'#{str.inspect[1..-2]}'"
    end
    
    def entity(name, context, block)
      output << "rule #{name}\n"
      
      contents = context.instance_eval(&block)
      contents.accept(self)
      
      output << "end\n"
    end

    def named(name, parslet)
      parslet.accept(self)
    end

    def sequence(parslets)
      parslets.each do |parslet|
        parslet.accept(self)
        output << ' '
      end
    end

    def repetition(min, max, parslet)
      parslet.accept(self)
      output << "{#{min}, #{max}}"
    end

    def alternative(alternatives)
      alternatives.each do |parslet|
        parslet.accept(self)
        output << " / "
      end
    end

    def lookahead(positive, bound_parslet)
      output << (positive ? '&' : '!')
      bound_parslet.accept(self)
    end

    def re(match)
      output << match.inspect
    end
  end
  
  # Exports this parser as a string in Treetop lingo. The resulting Treetop
  # grammar will not have any actions. 
  #
  def to_treetop
    visitor = GrammarPrintVisitor.new
    root.accept(visitor)
  end
end

