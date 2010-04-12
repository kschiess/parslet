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
end

require 'parslet/atoms'
require 'parslet/pattern'