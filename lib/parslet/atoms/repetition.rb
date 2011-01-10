
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
    @parslet = parslet
    @min, @max = min, max
    @tag = tag
  end
  
  def try(io) # :nodoc:
    occ = 0
    result = [@tag]   # initialize the result array with the tag (for flattening)
    catch(:error) {
      result << parslet.apply(io)
      occ += 1
      
      # If we're not greedy (max is defined), check if that has been 
      # reached. 
      return result if max && occ>=max
      redo
    }
    
    # Greedy matcher has produced a failure. Check if occ (which will
    # contain the number of sucesses) is in {min, max}.
    # p [:repetition, occ, min, max]
    error(io, "Expected at least #{min} of #{parslet.inspect}") if occ < min
    return result
  end
  
  precedence REPETITION
  def to_s_inner(prec) # :nodoc:
    minmax = "{#{min}, #{max}}"
    minmax = '?' if min == 0 && max == 1

    parslet.to_s(prec) + minmax
  end

  def cause # :nodoc:
    # Either the repetition failed or the parslet inside failed to repeat. 
    super || parslet.cause
  end
  def error_tree # :nodoc:
    if cause?
      Parslet::ErrorTree.new(self, parslet.error_tree)
    else
      parslet.error_tree
    end
  end
end

