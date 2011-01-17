# Matches a special kind of regular expression that only ever matches one
# character at a time. Useful members of this family are: character ranges, 
# \w, \d, \r, \n, ...
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

    @match = match
    @re    = Regexp.new(match, Regexp::MULTILINE)
    @error_msgs = {
      :premature  => "Premature end of input", 
      :failed     => "Failed to match #{match.inspect[1..-2]}"
    }
  end

  def try(source) # :nodoc:
    start_pos = source.pos
    s = source.read(1)
    error(source, @error_msgs[:premature], start_pos) unless s
    error(source, @error_msgs[:failed], start_pos) unless s.match(re)
    return s
  end

  def to_s_inner(prec) # :nodoc:
    match.inspect[1..-2]
  end
end

