class Parslet::Parser
  
  # Packages the common idiom
  #    
  #    begin
  #      tree = parser.parse('something')
  #    rescue Parslet::ParseFailed => error
  #      puts error
  #      puts parser.root.error_tree
  #    end
  #
  # into a convenient method.
  #
  # Usage:
  #   
  #   require 'parslet'
  #   require 'parslet/convenience'
  #   
  #   class FooParser < Parslet::Parser
  #     rule(:foo) { str('foo') }
  #     root(:foo)
  #   end
  #   
  #   FooParser.new.parse_with_debug('bar')
  #
  def parse_with_debug str
    parse str
  rescue Parslet::ParseFailed => error
    puts error
    puts root.error_tree
  end

end