require 'stringio'

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
  def sequence(symbol)
    Pattern::SequenceBind.new(symbol)
  end
  module_function :sequence
  
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