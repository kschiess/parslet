# Allows exporting parslet grammars to other lingos. 

class Parslet::Parser
  # Some metaprogramming to intercept the creation of rules in the parsers
  # that will be defined after this file is loaded. 
  class << self
    alias rule_without_capture rule
    def rule(name, &definition)
      @rules ||= []
      @rules << [name, definition]
      rule_without_capture(name, &definition)
    end
    
    alias root_without_capture root
    def root(name)
      @root = name
      root_without_capture(name)
    end

    def grammar
      [@root, @rules]
    end
  end
  
  # Exports this parser as a string in Treetop lingo. The resulting Treetop
  # grammar will not have any actions. 
  #
  def to_treetop
    text = ""
    
    text << "grammar " << self.class.name << "\n"

    root, rules = self.class.grammar
    rules.each do |name, _|
      text << "  rule " << name.to_s << "\n"
      text << "    " << self.send(name).parslet.inspect << "\n"
      text << "  end\n"
    end
    
    text << "end"
    
    text
  end
end

