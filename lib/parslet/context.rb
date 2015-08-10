
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
  
  def meta_def(name, &body)
    metaclass = class <<self; self; end

    metaclass.send(:define_method, name, &body)
  end
  
  def initialize(bindings)
    bindings.each do |key, value|
      meta_def(key.to_sym) { value }
      instance_variable_set("@#{key}", value)
    end
  end

  # following methods are needed and were provided by blankslate
  def methods
    [:==, :equal?, :!, :!=, :instance_eval, :instance_exec, :__send__, :__id__]
  end

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