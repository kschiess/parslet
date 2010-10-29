# Basically just demonstrates that you can leave rules empty and get a nice
# NotImplementedError. A way to quickly spec out your parser rules?

$:.unshift '../lib'

require 'parslet'

class Parser
  include Parslet
  
  rule(:empty) { }
end


Parser.new.empty.parslet