# Matches a special kind of regular expression that only ever matches one
# character at a time. Useful members of this family are: <code>character
# ranges, \\w, \\d, \\r, \\n, ...</code>
#
# Example: 
#
#   match('[a-z]')  # matches a-z
#   match('\s')     # like regexps: matches space characters
#
class Parslet::Atoms::Re < Parslet::Atoms::Base
  attr_reader :match, :re
  def initialize(match) # :nodoc:
    super()

    @match = match.to_s
    @re    = Regexp.new(self.match, Regexp::MULTILINE)
    @error_msgs = {
      :premature  => "Premature end of input", 
      :failed     => "Failed to match #{match.inspect[1..-2]}"
    }
  end

  def try(source, context) # :nodoc:
    error_pos = source.pos
    s = source.read(1)
    
    return error(source, @error_msgs[:premature], error_pos) unless s
    return error(source, @error_msgs[:failed], error_pos) unless s.match(re)
    
    return success(s)
  end

  def to_s_inner(prec) # :nodoc:
    match.inspect[1..-2]
  end
end

