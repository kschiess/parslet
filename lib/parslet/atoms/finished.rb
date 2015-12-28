# Consumes the remainder of the input. This is equivalent
# to 'any.repeat' but performs significantly faster. It is
# intended to be used when the desired pattern has been detected
# and the rest of the input should be ignored.
#
# Example:
#
#   ignore # ignores subsequent input
#
class Parslet::Atoms::Finished < Parslet::Atoms::Base
  attr_reader :str
  def initialize
    super
  end

  def try(source, context, consume_all)
    return succ(source.consume(source.chars_left))
  end

  def to_s_inner(prec)
    "finished"
  end
end
