require 'stringio'

module Parslet
  def named(name, &block)
    Matchers::Entity.new(name, block)
  end
  module_function :named
  
  def match(obj)
    Matchers::Re.new(obj)
  end
  module_function :match
  
  def str(str)
    Matchers::Str.new(str)
  end
  module_function :str
  
  def any
    Matchers::Re.new('.')
  end
  module_function :any
end

require 'parslet/matchers'