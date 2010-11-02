require 'stringio'

# A simple parser generator library. Typical usage would look like this: 
#
#   require 'parslet'
#        
#   class MyParser
#     include Parslet
#        
#     rule(:a) { str('a').repeat }
#        
#     def parse(str)
#       a.parse(str)
#     end
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
# * Parsing the input string; this yields an intermediary tree
# * Transformation of the tree into something useful to you
#
# The first stage is traditionally intermingled with the second stage; output
# from the second stage is usually called the 'Abstract Syntax Tree' or AST. 
#
# The stages are completely decoupled; You can change your grammar around 
# and use the second stage to isolate the rest of your code from the changes
# you've effected. 
#
# = Language Atoms
#
# PEG-style grammars build on a very small number of atoms, or parslets. In
# fact, only three types of parslets exist. Here's how to match a string: 
#
#   str('a string')
#
# This matches the string 'a string' literally and nothing else. If your input
# doesn't contain the string, it will fail. Here's how to match a character
# set: 
#
#   match('[abc]')
#
# This matches 'a', 'b' or 'c'. The string matched will always have a length
# of 1; to match longer strings, please see the title below. The last parslet
# of the three is 'any':
#
#   any
#
# 'any' functions like the dot in regular expressions - it matches any single
# character. 
#
# = Combination and Repetition
#
# Parslets only get useful when combined to grammars. To combine one parslet
# with the other, you have 4 kinds of methods available: repeat and maybe, >>
# (sequence), | (alternation), absnt? and prsnt?.
#
#   str('a').repeat     # any number of 'a's, including 0
#   str('a').maybe      # maybe there'll be an 'a', maybe not   
#
# Parslets can be joined using >>. This means: Match the left parslet, then
# match the right parslet. 
#
#   str('a') >> str('b')  # would match 'ab'
#
# Keep in mind that all combination and repetition operators themselves return
# a parslet. You can combine the result again: 
#
#   ( str('a') >> str('b') ) >> str('c')    # would match 'abc'
#    
# The slash ('|') indicates alternatives: 
#
#   str('a') | str('b')   # would match 'a' OR 'b'
#
# The left side of an alternative is matched first; if it matches, the right
# side is never looked at. 
#
# The absnt? and prsnt? qualifiers allow looking at input without consuming
# it: 
#
#   str('a').absnt?               # will match if at the current position there is an 'a'. 
#   str('a').absnt? >> str('b')   # check for 'a' then match 'b'
#
# This means that the second example will not match any input; when the second
# part is parsed, the first part has asserted the presence of 'a', and thus
# str('b') cannot match. The prsnt? method is the opposite of absnt?, it
# asserts presence. 
#    
# More documentation on these methods can be found in Parslets::Atoms::Base.
#
# = Intermediary Parse Trees
# 
# As you have probably seen above, you can hand input (strings or StringIOs) to
# your parslets like this: 
#
#   parslet.parse(str)    
#
# This returns an intermediary parse tree or raises an exception
# (Parslet::ParseFailed) when the input is not well formed. 
#
# Intermediary parse trees are essentially just Plain Old Ruby Objects. (PORO
# technology as we call it.) Parslets try very hard to return sensible stuff; 
# it is quite easy to use the results for the later stages of your program. 
#
# Here a few examples and what their intermediary tree looks like: 
#
#   str('foo').parse('foo')                           # => 'foo'
#   (str('f') >> str('o') >> str('o')).parse('foo')   # => 'foo'
#   
# Naming parslets
#
# Construction of lambda blocks
#
# = Intermediary Tree transformation
#
# The intermediary parse tree by itself is most often not very useful. Its
# form is volatile; changing your parser in the slightest might produce
# profound changes in the generated trees. 
#
# Generally you will want to construct a more stable tree using your own
# carefully crafted representation of the domain. Parslet provides you with
# an elegant way of transmogrifying your intermediary tree into the output
# format you choose. This is achieved by transformation rules such as this
# one: 
#
#   transform.rule(:literal => {:string => :_x}) { |d| 
#     StringLit.new(*d.values) }
# 
# The above rule will transform a subtree looking like this: 
#
#                              :literal
#                                   |     
#                               :string    
#                                   |
#                              "somestring"
#
# into just this: 
#
#                               StringLit
#                               value: "somestring"
#
#
# = Further documentation
#
# Please see the examples subdirectory of the distribution for more examples.
# Check out 'rooc' (github.com/kschiess/rooc) as well - it uses parslet for
# compiler construction. 
#       
module Parslet
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  # This is raised when the parse failed to match or to consume all its input.
  # It contains the message that should be presented to the user. If you want
  # to display more error explanation, you can print the #error_tree that is
  # stored in the parslet. This is a graphical representation of what went
  # wrong. 
  #
  # Example: 
  #    
  #   begin
  #     parslet.parse(str)
  #   rescue Parslet::ParseFailed => failure
  #     puts parslet.error_tree.ascii_tree
  #   end
  #
  class ParseFailed < Exception
  end
  
  module ClassMethods
    # Define the parsers #root function. This is the place where you start 
    # parsing; if you have a rule for 'file' that describes what should be 
    # in a file, this would be your root declaration: 
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
    
    # Define an entity for the parser. This generates a method of the same name
    # that can be used as part of other patterns. Those methods can be freely
    # mixed in your parser class with real ruby methods.
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
    #     def parse(str)
    #       twobar.parse(str)
    #     end
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
  
  # Returns an atom matching a character class. This is essentially a regular
  # expression, but you should only match a single character. 
  #
  # Example: 
  #
  #   match('[ab]')     # will match either 'a' or 'b'
  #   match('[\n\s]')   # will match newlines and spaces
  #
  def match(obj)
    Atoms::Re.new(obj)
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
  #   exp(%Q("a" "b"?))     # => returns the same as str('a') >> str('b').absnt?
  #
  def exp(str)
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
  
  autoload :Expression, 'parslet/expression'
end

require 'parslet/error_tree'
require 'parslet/atoms'
require 'parslet/pattern'
require 'parslet/pattern/binding'
require 'parslet/transform'