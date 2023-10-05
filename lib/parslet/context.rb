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
class Parslet::Context
  include Parslet

  def initialize(bindings, transform = nil)
    @__transform = transform if transform
    bindings.each do |key, value|
      singleton_class.send(:define_method, key) { value }
      instance_variable_set("@#{key}", value)
    end
  end

  def respond_to_missing?(method, include_private)
    super || @__transform&.respond_to?(method, true) || false
  end

  if RUBY_VERSION >= '3'
    def method_missing(method, *args, **kwargs, &block)
      if @__transform&.respond_to?(method, true)
        @__transform.__send__(method, *args, **kwargs, &block)
      else
        super
      end
    end
  else
    def method_missing(method, *args, &block)
      if @__transform&.respond_to?(method, true)
        @__transform.__send__(method, *args, &block)
      else
        super
      end
    end

    ruby2_keywords :method_missing
  end
end
