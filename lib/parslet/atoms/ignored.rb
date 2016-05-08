# Names a match to influence tree construction.
#
# Example:
#
#   str('foo')            # will return 'foo',
#   str('foo').as(:foo)   # will return :foo => 'foo'
#
class Parslet::Atoms::Ignored < Parslet::Atoms::Base
  attr_reader :parslet
  def initialize(parslet)
    super()

    @parslet = parslet
  end

  def apply(source, context, consume_all)
    success, _ = result = parslet.apply(source, context, consume_all)

    return result unless success
    succ(nil)
  end
  
  def to_s_inner(prec)
    "ignored(#{parslet.to_s(prec)})"
  end
end
