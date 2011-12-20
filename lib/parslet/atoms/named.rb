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
    super()

    @parslet, @name = parslet, name
  end

  def apply(source, context) # :nodoc:
    value = parslet.apply(source, context)

    if name.nil?
      success(nil)
    else
      return value if value.error?
      success(
        produce_return_value(
          value.result))
    end
  end

  def to_s_inner(prec) # :nodoc:
    "#{name}:#{parslet.to_s(prec)}"
  end

  def error_tree # :nodoc:
    parslet.error_tree
  end
private
  def produce_return_value(val) # :nodoc:
    { name => flatten(val, true) }
  end
end
