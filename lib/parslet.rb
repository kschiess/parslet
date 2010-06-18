require 'stringio'

module Parslet
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    # Parser structure ---------------------------------------------------------
  
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
  
  # Text matching ------------------------------------------------------------
  
  def match(obj)
    Atoms::Re.new(obj)
  end
  module_function :match
  
  def str(str)
    Atoms::Str.new(str)
  end
  module_function :str
  
  def any
    Atoms::Re.new('.')
  end
  module_function :any

  # Tree matching ------------------------------------------------------------
  
  def sequence(symbol)
    Pattern::SequenceBind.new(symbol)
  end
  module_function :sequence
  
  def simple(symbol)
    Pattern::SimpleBind.new(symbol)
  end
  module_function :simple

  # def named(name, &block)
  #   Atoms::Entity.new(name, block)
  # end
  # module_function :named
end

require 'parslet/error_tree'
require 'parslet/atoms'
require 'parslet/pattern'
require 'parslet/pattern/binding'
require 'parslet/transform'