class Parslet::Atoms::Base
  
  # TODO
  # Packages the common idiom
  #    
  #    begin
  #      tree = parser.parse('something')
  #    rescue Parslet::ParseFailed => error
  #      puts error
  #      puts parser.error_tree
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
  def parse_with_debug str, opts={}
    parse str, opts
  rescue Parslet::UnconsumedInput => error
    puts error
  rescue Parslet::ParseFailed => error
    puts error.cause.ascii_tree
  end

end