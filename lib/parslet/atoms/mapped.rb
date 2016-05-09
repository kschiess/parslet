# Applies a function on a parse result to influence tree construction. 
#
# Example: 
#
#   str('foo')                                   # will return 'foo', 
#   str('foo').map(lambda { |x| x.to_s.upcase }) # will return 'FOO'
#
class Parslet::Atoms::Mapped < Parslet::Atoms::Base
  attr_reader :parslet, :f
  def initialize(parslet, f)
    super()

    @parslet, @f = parslet, f
  end
  
  def apply(source, context, consume_all)
    success, value = result = parslet.apply(source, context, consume_all)

    return result unless success
    succ(f.call(value))
  end
  
  def to_s_inner(prec)
    parslet.to_s(prec)
  end
end
