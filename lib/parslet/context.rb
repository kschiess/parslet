
# Provides a context for tree transformations to run in. The context allows
# accessing each of the bindings in the bindings hash as local method.
#
# Example:
#
#   ctx = Context.new(:a => :b)
#   ctx.instance_eval do
#     a # => :b
#   end
#
# @api private
class Parslet::Context < BasicObject

# strangely including Parslet does not work anymore (when switching to BasicObject)
# and maybe even more strange is that it is not needed, all tests green
#  include Parslet

  attr_reader :methods

  def meta_def(name, &body)
    metaclass = class << self; self; end
    metaclass.send(:define_method, name, &body)
  end

  def initialize(bindings)
    @methods = [:==, :equal?, :!, :!=, :instance_eval, :instance_exec, :__send__, :__id__]
    @bindings = bindings
    bindings.each do |key, value|
      meta_def(key.to_sym) { value }
      instance_variable_set("@#{key}", value)
    end
  end

  def singleton_method_added name
    @methods << name
  end

  def respond_to? meth
    methods.include? meth
  end

  def to_s
    "#<Parslet::Context:0x#{self.__id__.to_s(16)}>"
  end

  def inspect
    str = "#<Parslet::Context:0x#{self.__id__.to_s(16)}"
    @bindings.each do |k,v|
      str += " @#{k}=#{v}"
    end
    str + ">"
  end

  # following methods are needed and were provided by blankslate
  def instance_variable_set a , b
    instance_eval "a = b"
  end

  # Also all these Kernel methods are not available in BasicObject, but used in acceptance tests
  def Integer(i)
    ::Kernel::Integer(i)
  end
  def String(s)
    ::Kernel::String(s)
  end
  def Float(f)
    ::Kernel::Float(f)
  end
  def puts s
    ::Kernel.puts(s)
  end
  def eval str , con
    ::Kernel.eval(str , con)
  end

end
