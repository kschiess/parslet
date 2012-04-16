
# Matches a parslet repeatedly. 
#
# Example: 
#
#   str('a').repeat(1,3)  # matches 'a' at least once, but at most three times
#   str('a').maybe        # matches 'a' if it is present in the input (repeat(0,1))
#
class Parslet::Atoms::Repetition < Parslet::Atoms::Base  
  attr_reader :min, :max, :parslet
  def initialize(parslet, min, max, tag=:repetition)
    super()

    @parslet = parslet
    @min, @max = min, max
    @tag = tag
    @error_msgs = {
      :minrep  => "Expected at least #{min} of #{parslet.inspect}"
    }
  end
  
  def try(source, context) # :nodoc:
    occ = 0
    result = [@tag]   # initialize the result array with the tag (for flattening)
    start_pos = source.pos
    break_on = nil
    loop do
      value = parslet.apply(source, context)

      break_on = value
      break if value.error?

      occ += 1
      result << value.result
      
      # If we're not greedy (max is defined), check if that has been 
      # reached. 
      return success(result) if max && occ>=max
    end
    
    # assert: value.error? is true
    
    # Greedy matcher has produced a failure. Check if occ (which will
    # contain the number of sucesses) is in {min, max}.
    return error_at(
      source, 
      @error_msgs[:minrep], 
      start_pos, 
      [break_on.message]) if occ < min
      
    return success(result)
  end
  
  precedence REPETITION
  def to_s_inner(prec) # :nodoc:
    minmax = "{#{min}, #{max}}"
    minmax = '?' if min == 0 && max == 1

    parslet.to_s(prec) + minmax
  end
end

