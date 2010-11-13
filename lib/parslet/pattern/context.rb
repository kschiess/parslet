require 'blankslate'

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
class Parslet::Pattern::Context < BlankSlate
  def initialize(bindings)
    @bindings = bindings
  end
  
  def method_missing(sym, *args, &block)
    super unless args.empty?
    super unless @bindings.has_key?(sym.to_sym)
    
    @bindings[sym]
  end
end