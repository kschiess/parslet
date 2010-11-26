require 'stringio'

# A simple parser generator library. Typical usage would look like this: 
#
#   require 'parslet'
#        
#   class MyParser < Parslet::Parser
#     rule(:a) { str('a').repeat }
#     root(:a)        
#   end
#        
#   pp MyParser.new.parse('aaaa')   # => 'aaaa'
#   pp MyParser.new.parse('bbbb')   # => Parslet::Atoms::ParseFailed: 
#                                   #    Don't know what to do with bbbb at line 1 char 1.
#
# The simple DSL allows you to define grammars in PEG-style. This kind of
# grammar construction does away with the ambiguities that usually comes with
# parsers; instead, it allows you to construct grammars that are easier to
# debug, since less magic is involved. 
#
# Parslet is typically used in stages: 
#
# 
# * Parsing the input string; this yields an intermediary tree, see Parslet.any, Parslet.match, 
#   Parslet.str, Parslet::ClassMethods#rule and Parslet::ClassMethods#root.
# * Transformation of the tree into something useful to you, see Parslet::Transform, 
#   Parslet.simple, Parslet.sequence and Parslet.subtree.
#
# The first stage is traditionally intermingled with the second stage; output
# from the second stage is usually called the 'Abstract Syntax Tree' or AST. 
#
# The stages are completely decoupled; You can change your grammar around 
# and use the second stage to isolate the rest of your code from the changes
# you've effected. 
#
# == When things go wrong
#
# A parse that fails will raise Parslet::ParseFailed. A detailed explanation
# of what went wrong can be obtained from the parslet involved or the root
# of the parser instance. 
#
module Parslet
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  # Raised when the parse failed to match or to consume all its input. It
  # contains the message that should be presented to the user. If you want to
  # display more error explanation, you can print the #error_tree that is
  # stored in the parslet. This is a graphical representation of what went
  # wrong. 
  #
  # Example: 
  #     
  #   begin
  #     parslet.parse(str)
  #   rescue Parslet::ParseFailed => failure
  #     puts parslet.error_tree
  #   end
  #
  class ParseFailed < Exception
  end
  
  module ClassMethods
    # Define the parsers #root function. This is the place where you start 
    # parsing; if you have a rule for 'file' that describes what should be 
    # in a file, this would be your root declaration: 
    #
    #   class Parser
    #     root :file
    #     rule(:file) { ... }
    #   end
    #
    # #root declares a 'parse' function that works just like the parse 
    # function that you can call on a simple parslet, taking a string as input
    # and producing parse output. 
    #
    # In a way, #root is a shorthand for: 
    #
    #   def parse(str)
    #     your_parser_root.parse(str)
    #   end
    #
    def root(name)
      define_method(:root) do
        self.send(name)
      end
      define_method(:parse) do |str|
        root.parse(str)
      end
    end
    
    # Define an entity for the parser. This generates a method of the same
    # name that can be used as part of other patterns. Those methods can be
    # freely mixed in your parser class with real ruby methods.
    #
    # Example: 
    #
    #   class MyParser
    #     include Parslet
    #
    #     rule :bar { str('bar') }
    #     rule :twobar do
    #       bar >> bar
    #     end
    #
    #     root :twobar
    #   end
    #
    def rule(name, &definition)
      define_method(name) do
        @rules ||= {}     # <name, rule> memoization
        @rules[name] or
          (@rules[name] = Atoms::Entity.new(name, self, definition))
      end
    end
  end

  # Allows for delayed construction of #match. See also Parslet.match.
  #
  class DelayedMatchConstructor #:nodoc:
    def [](str)
      Atoms::Re.new("[" + str + "]")
    end
  end
  
  # Returns an atom matching a character class. All regular expressions can be
  # used, as long as they match only a single character at a time. 
  #
  # Example: 
  #
  #   match('[ab]')     # will match either 'a' or 'b'
  #   match('[\n\s]')   # will match newlines and spaces
  #
  # There is also another (convenience) form of this method: 
  #
  #   match['a-z']      # synonymous to match('[a-z]')
  #   match['\n']       # synonymous to match('[\n]')
  #
  def match(str=nil)
    return DelayedMatchConstructor.new unless str
    
    return Atoms::Re.new(str)
  end
  module_function :match
  
  # Returns an atom matching the +str+ given. 
  #
  # Example: 
  #
  #   str('class')      # will match 'class' 
  #
  def str(str)
    Atoms::Str.new(str)
  end
  module_function :str
  
  # Returns an atom matching any character. 
  #
  def any
    Atoms::Re.new('.')
  end
  module_function :any
  
  # A special kind of atom that allows embedding whole treetop expressions
  # into parslet construction. 
  #
  # Example: 
  #
  #   exp(%Q("a" "b"?))     # => returns the same as str('a') >> str('b').maybe
  #
  def exp(str) # :nodoc:
    Parslet::Expression.new(str).to_parslet
  end
  module_function :exp
  
  # Returns a placeholder for a tree transformation that will only match a 
  # sequence of elements. The +symbol+ you specify will be the key for the 
  # matched sequence in the returned dictionary.
  #
  # Example: 
  #
  #   # This would match a body element that contains several declarations.
  #   { :body => sequence(:declarations) }
  #
  # The above example would match :body => ['a', 'b'], but not :body => 'a'. 
  #
  def sequence(symbol)
    Pattern::SequenceBind.new(symbol)
  end
  module_function :sequence
  
  # Returns a placeholder for a tree transformation that will only match 
  # simple elements. This matches everything that #sequence doesn't match.
  #
  # Example: 
  #
  #   # Matches a single header. 
  #   { :header => simple(:header) }
  #
  def simple(symbol)
    Pattern::SimpleBind.new(symbol)
  end
  module_function :simple
  
  # Returns a placeholder for tree transformation patterns that will match 
  # any kind of subtree. 
  #
  # Example: 
  #
  #   { :expression => subtree(:exp) }
  #
  def subtree(symbol)
    Pattern::SubtreeBind.new(symbol)
  end
  
  autoload :Expression, 'parslet/expression'
end

require 'parslet/error_tree'
require 'parslet/atoms'
require 'parslet/pattern'
require 'parslet/pattern/binding'
require 'parslet/transform'
require 'parslet/parser'