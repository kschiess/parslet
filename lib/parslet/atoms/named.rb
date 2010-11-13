class Parslet::Atoms::Named < Parslet::Atoms::Base
  attr_reader :parslet, :name
  def initialize(parslet, name)
    @parslet, @name = parslet, name
  end
  
  def apply(io)
    value = parslet.apply(io)
    
    produce_return_value value
  end
  
  def to_s_inner(prec)
    "#{name}:#{parslet.to_s(prec)}"
  end

  def error_tree
    parslet.error_tree
  end
private
  def produce_return_value(val)  
    { name => flatten(val) }
  end
end
