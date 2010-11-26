# Names a match to influence tree construction. 
#
# Example: 
#
#   str('foo')            # will return 'foo', 
#   str('foo').as(:foo)   # will return :foo => 'foo'
#
class Parslet::Atoms::Named < Parslet::Atoms::Base
  attr_reader :parslet, :name
  def initialize(parslet, name) # :nodoc:
    @parslet, @name = parslet, name
  end
  
  def apply(io) # :nodoc:
    value = parslet.apply(io)
    
    produce_return_value value
  end
  
  def to_s_inner(prec) # :nodoc:
    "#{name}:#{parslet.to_s(prec)}"
  end

  def error_tree # :nodoc:
    parslet.error_tree
  end
private
  def produce_return_value(val) # :nodoc:
    { name => flatten(val) }
  end
end
