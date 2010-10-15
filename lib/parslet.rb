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
# = Language Atoms
#
# PEG-style grammars build on a very small number of atoms, or parslets as
# I'll call them. In fact, only three types of parslets exist. Here's how to
# match a string: 
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
# (sequence), / (alternation), absnt? and prsnt?.
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
# The slash ('/') indicates alternatives: 
#
#   str('a') / str('b')   # would match 'a' OR 'b'
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
# = Output transformation
#   
# Naming parslets
# Construction of lambda blocks
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
  
  module ClassMethods
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
end

require 'parslet/error_tree'
require 'parslet/atoms'
require 'parslet/pattern'
require 'parslet/pattern/binding'
require 'parslet/transform'