# Make a mark, return the match as usual, but doesn't consume its input.
#
# Example:
#
#   str('foo').mark # matches when the input contains 'foo', but doesn't
#   consume the input, so other atoms have chance to parse the input.
#
class Parslet::Atoms::Mark < Parslet::Atoms::Base
  attr_reader :mark_parslet
  attr_reader :offset

  def initialize(mark_parslet, offset)
    super()

    @mark_parslet = mark_parslet       
    @offset = offset
  end

  def try(source, context, consume_all)
    source.pos += offset
    old_pos = source.pos
    success, value = result = mark_parslet.apply(source, context, consume_all)
    source.pos = old_pos-offset
    return result
  end

  def to_s_inner(prec)
    "MARK"
  end
end
