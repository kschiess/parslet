require 'stringio'

module Parslet
  def named(name, &block)
    Atoms::Entity.new(name, block)
  end
  module_function :named
  
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